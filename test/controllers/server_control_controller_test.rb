require 'test_helper'

class ServerControlControllerTest < ActionDispatch::IntegrationTest
  test "should post set_log_level" do
    post "/server_control/set_log_level", headers: jwt_header, params: { log_level: 'ERROR'}, as: :json
    assert_response :unauthorized

    post "/server_control/set_log_level", headers: jwt_header(@jwt_admin_token), params: { log_level: 'ERROR'}, as: :json
    assert_response :success
    assert Rails.logger.level == 3, 'Log level should be set to ERROR now'

    # reset level to DEBUG
    post "/server_control/set_log_level", headers: jwt_header(@jwt_admin_token), params: { log_level: 'DEBUG'}, as: :json
    assert_response :success
    assert Rails.logger.level == 0, 'Log level should be set to DEBUG now'

  end

  test "should post set_worker_threads_count" do
    ThreadHandling.get_instance.ensure_processing                               # Start worker threads, regularly not started for test

    post "/server_control/set_worker_threads_count", headers: jwt_header, params: { worker_threads_count: 3}, as: :json
    assert_response :unauthorized

    post "/server_control/set_worker_threads_count", headers: jwt_header(@jwt_admin_token), params: { worker_threads_count: 10}, as: :json
    assert_response :success
    assert ThreadHandling.get_instance.thread_count == 10, 'There should run 10 threads now'

    # reset level to DEBUG
    post "/server_control/set_worker_threads_count", headers: jwt_header(@jwt_admin_token), params: { worker_threads_count: 2}, as: :json
    assert_response :success
    assert ThreadHandling.get_instance.thread_count == 2, 'There should run 10 threads now'

    ThreadHandling.get_instance.shutdown_processing                             # Stop worker threads to restore normal test state
  end

end