require 'test_helper'

class DbColumnTest < ActiveSupport::TestCase

  test "get db columns" do
    db_columns = DbColumn.all_by_table(MovexCdc::Application.config.db_user, 'TABLES')
    assert db_columns.count > 0, log_on_failure('Should get at least one column of table')
  end

end
