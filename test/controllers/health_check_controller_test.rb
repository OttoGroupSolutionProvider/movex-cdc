require 'test_helper'

class HealthCheckControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do

    ThreadHandling.get_instance.ensure_processing
    loop_count = 0
    while loop_count < 10 do                                                  # wait up to x seconds for processing of event_logs records
      loop_count += 1
      event_logs = Database.select_one("SELECT COUNT(*) FROM Event_Logs")
      break if event_logs == 0                                                # All records processed, no need to wait anymore
      sleep 1
    end

    get "/health_check", as: :json
    Rails.logger.info @response.body
    if Trixx::Application.config.trixx_initial_worker_threads == ThreadHandling.get_instance.thread_count
      assert_response :success, '200 (success) expected because all worker threads are active'
    else
      assert_response :conflict, '409 (conflict) expected because not all worker threads are active'
    end

    get "/health_check", as: :json
    assert_response :internal_server_error, 'second check should fail within same second'

    ThreadHandling.get_instance.shutdown_processing
  end

  test "should get log_file" do
    get "/health_check/log_file", as: :json
    assert_response :unauthorized, 'No access without JWT'

    get "/health_check/log_file", headers: jwt_header, as: :json
    assert_response :success, 'should get log file with JWT'
  end
end
