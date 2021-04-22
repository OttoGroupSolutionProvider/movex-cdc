require 'test_helper'

class SchemaRightsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @schema_right = schema_rights(:one)
  end

  test "should get index" do
    # Setting params for get leads to switch GET to POST, only in test
    get "/schema_rights?user_id=1", headers: jwt_header(@jwt_admin_token), as: :json
    assert_response :success

    get "/schema_rights?schema_id=1", headers: jwt_header(@jwt_admin_token), as: :json
    assert_response :success

    get "/schema_rights?user_id=1", headers: jwt_header, as: :json
    assert_response :unauthorized, 'Should not get access without admin role'
  end

  test "should create schema_right" do
    assert_difference('SchemaRight.count') do
      post schema_rights_url, headers: jwt_header(@jwt_admin_token), params: { schema_right: { user_id: 2, schema_id: 1, info: 'Info' } }, as: :json
    end
    assert_response 201

    post schema_rights_url, headers: jwt_header, params: { schema_right: { user_id: 2, schema_id: 1, info: 'Info'  } }, as: :json
    assert_response :unauthorized, 'Should not get access without admin role'
  end

  test "should show schema_right" do
    get schema_right_url(@schema_right), headers: jwt_header(@jwt_admin_token), as: :json
    assert_response :success

    get schema_right_url(@schema_right), headers: jwt_header, as: :json
    assert_response :unauthorized, 'Should not get access without admin role'
  end

  test "should update schema_right" do
    patch schema_right_url(@schema_right), headers: jwt_header(@jwt_admin_token), params: { schema_right: { info: 'changed info', lock_version: @schema_right.lock_version } }, as: :json
    assert_response 200

    patch schema_right_url(@schema_right), headers: jwt_header, params: { schema_right: {  } }, as: :json
    assert_response :unauthorized, 'Should not get access without admin role'
  end

  test "should destroy schema_right" do
    schema_right_to_delete = SchemaRight.new(user_id: users(:no_schema_right).id, schema_id: schemas(:one).id)
    schema_right_to_delete.save!

    assert_difference('SchemaRight.count', -1) do
      delete schema_right_url(schema_right_to_delete), headers: jwt_header(@jwt_admin_token), params: { schema_right: schema_right_to_delete.attributes}, as: :json
    end
    assert_response 204

    if Trixx::Application.config.trixx_db_type != 'SQLITE'
      assert_raise ActiveRecord::StaleObjectError, 'Should raise ActiveRecord::StaleObjectError' do
        delete schema_right_url(schema_rights(:two)), headers: jwt_header(@jwt_admin_token), params: { schema_right: {lock_version: 42}}, as: :json
      end
    end

    delete schema_right_url(@schema_right), headers: jwt_header, as: :json
    assert_response :unauthorized, 'Should not get access without admin role'
  end
end
