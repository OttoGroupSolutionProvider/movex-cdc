class DbTrigger < ApplicationRecord

  # delegate method calls to DB-specific implementation classes
  METHODS_TO_DELEGATE = [
      :build_trigger_name,
      :find_all_by_schema_id,
      :find_all_by_table,
      :find_by_table_id_and_trigger_name,
  ]

  def self.method_missing(method, *args, &block)
    if METHODS_TO_DELEGATE.include?(method)
      target_class = case MovexCdc::Application.config.db_type
                     when 'ORACLE' then DbTriggerGeneratorOracle
                     when 'SQLITE' then DbTriggerGeneratorSqlite
                     else
                       raise "Unsupported value for MovexCdc::Application.config.db_type: '#{MovexCdc::Application.config.db_type}'"
                     end
      target_class.send(method, *args, &block)                                         # Call method with same name in target class
    else
      super
    end
  end

  def self.respond_to?(method, include_private = false)
    METHODS_TO_DELEGATE.include?(method) || super
  end

  # Generate triggers
  # @param schema_id      schema all pending triggers are generated for
  # @param dry_run        compile triggers or not
  # @param table_id_list  Array of table-IDs to generate triggers for, nil=all
  # @return { schema_id:,
  #   successes: [{table_id, table_name, trigger_name, sql}, ...],
  #   errors: [{table_id, table_name, trigger_name, exception_class, exception_message, sql}, ...],
  #   load_sqls: [{table_id, table_name, sql}, ...],
  #   }
  def self.generate_schema_triggers(schema_id:, dry_run: false, table_id_list: nil)
    schema = Schema.find schema_id
    generator = case MovexCdc::Application.config.db_type
                when 'ORACLE' then DbTriggerGeneratorOracle.new(schema_id: schema_id, dry_run: dry_run)
                when 'SQLITE' then DbTriggerGeneratorSqlite.new(schema_id: schema_id, dry_run: dry_run)
                else
                  raise "Unsupported value for MovexCdc::Application.config.db_type: '#{MovexCdc::Application.config.db_type}'"
                end

    generator.check_for_orphaned_triggers(schema)                               # check if triggers exist for not existing table IDs

    Table.where(schema_id: schema_id).each do |table|
      if table_id_list.nil? || table_id_list.include?(table.id)
        generator.generate_table_triggers(table_id: table.id) # check if drop or create trigger is to do
      end
    end

    generator.errors.each do |error|
      Rails.logger.error('DbTrigger.generate_schema_triggers'){ "Error creating trigger #{error[:trigger_name]}" }
      Rails.logger.error('DbTrigger.generate_schema_triggers'){ "#{error[:exception_class]}: #{error[:exception_message]}" }
      Rails.logger.error('DbTrigger.generate_schema_triggers'){ "#{error[:sql]}" }
    end

    unless dry_run
      # Schedule initialization of table data if requested
      generator.load_sqls.each do |load|
        Rails.logger.debug('DbTrigger.generate_schema_triggers'){ "Schedule table data initialization for #{schema.name}.#{load[:table_name]}" }
        TableInitialization.get_instance.add_table_initialization(load[:table_id], load[:table_name], load[:sql])
      end

      if MovexCdc::Application.config.db_type == 'SQLITE'
        # defer next processing until asynchronous processing of load_sqls has finished, to avoid connection concurrency
        max_wait_for_job = 100
        while (TableInitialization.get_instance.init_requests_count > 0 ||
          TableInitialization.get_instance.running_threads_count > 0) &&
          max_wait_for_job > 0 do
          max_wait_for_job -= 1                                                   # avoid unlimited loop
          sleep 1
        end
      end

      # Log activities
      schema.update!(last_trigger_deployment: Time.now) if generator.errors.count == 0  # Flag trigger generation successful
      generator.successes.each do |success_trigger|
        action = "Trigger #{success_trigger[:trigger_name]} successful created: #{success_trigger[:sql]}"[0, 500] # should be smaller than 1000 bytes
        ActivityLog.log_activity(schema_name: schema.name, table_name: success_trigger[:table_name], action: action)
      end
      generator.errors.each do |error_trigger|
        action = "Trigger #{error_trigger[:trigger_name]} created but with errors: #{error_trigger[:exception_class]}:#{error_trigger[:exception_message]} :  #{error_trigger[:sql]}"[0, 500] # should be smaller than 1000 bytes
        ActivityLog.log_activity(schema_name: schema.name, table_name: error_trigger[:table_name], action: action)
      end
    end

    { successes: generator.successes, errors: generator.errors, load_sqls: generator.load_sqls}
  end
end