# generated by: rails generate scaffold_controller Schema
class TablesController < ApplicationController
  before_action :set_table, only: [:show, :update, :trigger_dates]

  # GET /tables
  def index
    schema_id = params.require(:schema_id)                                      # should only list tables of specific schema
    @current_user.check_user_for_valid_schema_right(schema_id)

    @tables = Table.all_allowed_tables_for_schema(schema_id, @current_user.db_user).sort_by &:name
    render json: @tables
  end

  # GET /tables/1
  def show
    render json: @table
  end

  # GET /trigger_dates/1
  def trigger_dates
    dates = @table.youngest_trigger_change_dates_per_operation
    render json: {youngest_insert_trigger_changed_at: dates['I'], youngest_update_trigger_changed_at: dates['U'], youngest_delete_trigger_changed_at: dates['D']}
  end

  # POST /tables
  def create
    table_params.require([:schema_id, :name])
    schema = Schema.find(table_params[:schema_id].to_i)
    Table.check_table_allowed_for_db_user(current_user: @current_user, schema_name: schema.name, table_name: table_params[:name])

    tables = Table.where({ schema_id: table_params[:schema_id], name: table_params[:name]})   # Check for existing hidden or not hidden table
    if tables.length > 0                                                        # table still exists
      @table = tables[0]
      save_result = @table.update(table_params.to_h.merge({yn_hidden: 'N'}))    # mark visible for GUI
    else
      @table = Table.new(table_params)
      save_result = @table.save
    end

    if save_result
      log_activity(
          schema_name:  @table.schema.name,
          table_name:   @table.name,
          action:       "table inserted: #{@table.attributes}"
      )
      render json: @table, status: :created, location: @table
    else
      render json: { errors: @table.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /tables/1
  def update
    table_params.require(:lock_version)    # Ensure that column lock_version is sent as param from client
    if @table.update(table_params)
      log_activity(
          schema_name:  @table.schema.name,
          table_name:   @table.name,
          action:       "table updated: #{@table.attributes}"
      )
      render json: @table
    else
      render json: { errors: @table.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /tables/1
  def destroy
    @table = Table.find(params[:id].to_i)
    Table.check_table_allowed_for_db_user(current_user: @current_user, schema_name: @table.schema.name, table_name: @table.name, allow_for_nonexisting_table: true)
    @table.lock_version = table_params.require(:lock_version)    # Ensure that column lock_version is sent as param from client
    ActiveRecord::Base.transaction do
      @table.update!(yn_hidden: 'Y')
      Database.execute "UPDATE Columns SET YN_Log_Insert='N', YN_Log_Update='N', YN_Log_Delete='N' WHERE Table_ID = :id", {id: @table.id}
      log_activity(
        schema_name:  @table.schema.name,
        table_name:   @table.name,
        action:       "table marked hidden: #{@table.attributes}"
      )
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_table
    @table = Table.find(params[:id])
    Table.check_table_allowed_for_db_user(current_user: @current_user, schema_name: @table.schema.name, table_name: @table.name)
  end

  # Only allow a trusted parameter "white list" through.
  def table_params
    params.fetch(:table, {}).permit(:schema_id, :name, :info, :topic, :kafka_key_handling, :fixed_message_key, :lock_version, :yn_record_txid,
                                    :yn_initialization, :initialization_filter)
  end


end
