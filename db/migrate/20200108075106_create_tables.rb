class CreateTables < ActiveRecord::Migration[6.0]
  def change
    create_table :tables, comment: 'Tables planned for triger creation' do |t|
      t.references :schema,         null: false,  comment: 'Reference to schema'
      t.string :name, limit: 256,   null: false,  comment: 'Table name of database table'
      t.string :info, limit: 1000,  null: false,  comment: 'Additional info like responsible team'
      t.timestamps
    end

    add_foreign_key :tables, :schemas
    add_index :tables, [:schema_id, :name], name: 'ix_tables_schema_name', unique: true
  end

end