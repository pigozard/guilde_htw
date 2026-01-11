class WowClassesController < ApplicationController
  def specializations
    @wow_class = WowClass.find(params[:id])
    render json: @wow_class.specializations.select(:id, :name, :role)
  end
end
