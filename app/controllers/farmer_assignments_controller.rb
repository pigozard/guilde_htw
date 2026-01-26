class FarmerAssignmentsController < ApplicationController
  before_action :authenticate_user!

  def create
    @assignment = current_user.farmer_assignments.find_or_initialize_by(
      ingredient_id: params[:ingredient_id],
      week: Date.current.beginning_of_week
    )

    if @assignment.persisted?
      redirect_to farm_path, alert: "Tu es déjà positionné sur cet ingrédient !"
    elsif @assignment.save
      redirect_to farm_path, notice: "✅ Tu es maintenant assigné au farm de cet ingrédient !"
    else
      redirect_to farm_path, alert: "Erreur"
    end
  end

  def destroy
    @assignment = current_user.farmer_assignments.find(params[:id])
    @assignment.destroy
    redirect_to farm_path, notice: "Tu ne farm plus cet ingrédient"
  end
end
