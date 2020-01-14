# generated by: rails generate scaffold_controller Schema
class SchemasController < ApplicationController
  before_action :set_schema, only: [:show, :update, :destroy]

  # GET /schemas
  def index
    @schemas = Schema.all

    render json: @schemas
  end

  # GET /schemas/1
  def show
    render json: @schema
  end

  # POST /schemas
  def create
    @schema = Schema.new(schema_params)

    if @schema.save
      render json: @schema, status: :created, location: @schema
    else
      render json: @schema.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /schemas/1
  def update
    if @schema.update(schema_params)
      render json: @schema
    else
      render json: @schema.errors, status: :unprocessable_entity
    end
  end

  # DELETE /schemas/1
  def destroy
    @schema.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_schema
      @schema = Schema.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def schema_params
      params.fetch(:schema, {}).permit(:name)
    end
end