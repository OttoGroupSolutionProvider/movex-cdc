class CreateEventLogs < ActiveRecord::Migration[6.0]
  def up
    case Trixx::Application.config.trixx_db_type
    when 'ORACLE' then
      # Start MIN partition with current date to ensure less than 1 Mio. partitions within the next years
      EventLog.connection.execute("\
      CREATE TABLE Event_Logs (
        ID          NUMBER(38)    NOT NULL,
        Table_ID    NUMBER(38)    NOT NULL,
        Operation   CHAR(1)       NOT NULL,
        DBUser      VARCHAR2(128) NOT NULL,
        Payload     CLOB          NOT NULL,
        Created_At  TIMESTAMP(6)  NOT NULL
        )
        PCTFREE 0
        INITRANS 16
        LOB(Payload) STORE AS (CACHE)
        #{"PARTITION BY RANGE (Created_At) INTERVAL( NUMTODSINTERVAL(10,'MINUTE'))
           ( PARTITION MIN VALUES LESS THAN (TO_DATE('#{Time.now.strftime "%Y-%m-%d"} 00:00:00', 'YYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN')) )" if Trixx::Application.partitioning}
      ")
      # Sequence Event_Logs_Seq is generated by migration automatically
    else
      create_table :event_logs do |t|
        t.references  :table,                 null: false, comment: 'Reference to tables'
        t.string      :operation, limit: 1,   null: false, comment: 'Operation type /I/U/D'
        t.string      :dbuser,    limit: 128, null: false, comment: 'Name of connected DB user'
        t.text        :payload,               null: false, comment: 'Payload of message with old and new values'
        t.timestamp   :created_at,            null: false,  comment: 'Record creation timestamp'
      end
    end
  end

  def down
    drop_table(:event_logs)
  end
end
