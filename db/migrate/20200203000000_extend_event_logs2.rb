class ExtendEventLogs2 < ActiveRecord::Migration[6.0]

  # create primary key constraint for test, otherwise loading fixtures will result in error
  def up
    case MovexCdc::Application.config.db_type
    when 'ORACLE' then
      # MaxValue stored in DB is 999999999999999999 to fit in 64 bit long integer
      EventLog.connection.execute("CREATE SEQUENCE Event_Logs_SEQ MAXVALUE 999999999999999999 CACHE 100000 CYCLE")
    end
  end

  def down
    case MovexCdc::Application.config.db_type
    when 'ORACLE' then
      begin
        sql = "DROP SEQUENCE Event_Logs_SEQ"
        EventLog.connection.execute(sql)
      rescue Exception => e
        puts "Error: #{e.message}\nwhile executing:\n#{sql}"
      end
    end
  end

end
