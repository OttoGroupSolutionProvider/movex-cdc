class SchemaRightsController < ApplicationController
  before_action :check_for_current_user_admin
  before_action :set_schema_right, only: [:show, :update, :destroy]

  # GET /schema_rights
  def index
    # Should only list schema rights of specific user or schema
    index_params = params.permit [:user_id, :schema_id]
    if index_params[:user_id]
      @schema_rights = SchemaRight.where user_id: index_params[:user_id]
    else
      @schema_rights = SchemaRight.where schema_id: (params.require :schema_id)  # schema_id must be provided if user_id is not provided
    end

    render json: @schema_rights
  end

  # GET /schema_rights/1
  def show
    render json: @schema_right
  end

  # POST /schema_rights
  def create
    @schema_right = SchemaRight.new(schema_right_params)

    if @schema_right.save
      render json: @schema_right, status: :created, location: @schema_right
    else
      render json: { errors: @schema_right.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /schema_rights/1
  def update
    schema_right_params.require(:lock_version)    # Ensure that column lock_version is sent as param from client
    if @schema_right.update(schema_right_params)
      render json: @schema_right
    else
      render json: { errors: @schema_right.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /schema_rights/1
  def destroy
    @schema_right.lock_version = schema_right_params.require(:lock_version)    # Ensure that column lock_version is sent as param from client
    @schema_right.destroy!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_schema_right
      @schema_right = SchemaRight.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def schema_right_params
      params.fetch(:schema_right, {}).permit(:user_id, :schema_id, :info, :lock_version, :yn_deployment_granted)
    end
end
