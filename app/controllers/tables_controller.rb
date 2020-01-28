# generated by: rails generate scaffold_controller Schema
class TablesController < ApplicationController
  before_action :set_table, only: [:show, :update, :destroy]

  # GET /tables
  def index
    schema_id = params.require(:schema_id)                                      # should only list tables of specific schema
    check_user_for_valid_schema_right(schema_id)

    @tables = Table.where schema_id: schema_id
    render json: @tables
  end

  # GET /tables/1
  def show
    render json: @table
  end

  # POST /tables
  def create
    table_params.require([:schema_id, :name])
    @table = Table.new(table_params)
    check_user_for_valid_schema_right(@table.schema_id)

    if @table.save
      log_activity(
          schema_name:  @table.schema.name,
          table_name:   @table.name,
          action:       "table inserted: #{@table.attributes}"
      )
      render json: @table, status: :created, location: @table
    else
      render json: @table.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /tables/1
  def update
    if @table.update(table_params)
      log_activity(
          schema_name:  @table.schema.name,
          table_name:   @table.name,
          action:       "table updated: #{@table.attributes}"
      )
      render json: @table
    else
      render json: @table.errors, status: :unprocessable_entity
    end
  end

  # DELETE /tables/1
  def destroy
    @table.destroy
    log_activity(
        schema_name:  @table.schema.name,
        table_name:   @table.name,
        action:       "table deleted: #{@table.attributes}"
    )
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_table
    @table = Table.find(params[:id])
    check_user_for_valid_schema_right(@table.schema_id)
  end

  # Only allow a trusted parameter "white list" through.
  def table_params
    params.fetch(:table, {}).permit(:schema_id, :name, :info)
  end


end
