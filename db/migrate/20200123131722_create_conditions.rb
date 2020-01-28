class CreateConditions < ActiveRecord::Migration[6.0]
  def change
    create_table :conditions do |t|
      t.references  :table,           null: false,  comment: 'Reference to table'
      t.string      :operation,       limit: 1,     null: false,  comment: 'Type of operation: I=insert, U=update, D=delete'
      t.string      :filter,          limit: 4000,  null: false,  comment: 'Filter exporession for WHEN-clause of trigger'
      t.timestamps
    end
  end
end
