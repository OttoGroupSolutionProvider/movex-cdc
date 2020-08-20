require 'test_helper'

class TransferThreadTest < ActiveSupport::TestCase

  test "create worker" do
    worker = TransferThread.create_worker(2, max_transaction_size: 10000, max_message_bulk_count: 1000, max_buffer_bytesize: 100000) # Async. thread
    sleep(1)
    worker.stop_thread
  end

  test "process" do
    original_worker_threads = Trixx::Application.config.trixx_initial_worker_threads
    Trixx::Application.config.trixx_initial_worker_threads = 1                  # Ensure that all keys are matching to this worker thread by MOD
    create_event_logs_for_test(10)

    Rails.logger.debug "Event_Logs records before processing"
    log_event_logs_content(console_output: false)

    worker = TransferThread.new(1, max_transaction_size: 10000, max_message_bulk_count: 1000, max_buffer_bytesize: 100000)  # Sync. call within one thread

    # Stop process in separate thread after 10 seconds because following call of 'process' will never end without that
    Thread.new do
      loop_count = 0
      while loop_count < 20 do                                                  # wait up to x seconds for processing
        loop_count += 1
        event_logs = Database.select_one("SELECT COUNT(*) FROM Event_Logs")
        break if event_logs == 0                                                # All records processed, no need to wait anymore
        sleep 1
      end
      worker.stop_thread
    end

    worker.process                                                              # only synchrone execution ensures valid test of function
    event_log_count = Database.select_one("SELECT COUNT(*) FROM Event_Logs")

    log_event_logs_content(console_output: true) if event_log_count > 0                               # List remaining events from table

    assert_equal 0, event_log_count, 'All Records from Event_Logs should be processed and deleted now'

    Trixx::Application.config.trixx_initial_worker_threads = original_worker_threads  # Restore possibly differing value
  end

end
