class FarmContributionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_contribution, only: [:update, :destroy]
  before_action :authorize_owner!, only: [:update, :destroy]

  def create
    @contribution = current_user.farm_contributions.build(contribution_params)
    @contribution.week = Date.current.beginning_of_week

    if @contribution.save
      redirect_to farm_path, notice: "Contribution ajoutée ! 🎉"
    else
      redirect_to farm_path, alert: "Erreur : #{@contribution.errors.full_messages.join(', ')}"
    end
  end

  def update
    if @contribution.update(contribution_params)
      redirect_to farm_path, notice: "Contribution mise à jour !"
    else
      redirect_to farm_path, alert: "Erreur lors de la mise à jour."
    end
  end

  def destroy
    @contribution.destroy
    redirect_to farm_path, notice: "Contribution supprimée."
  end

  private

  def set_contribution
    @contribution = FarmContribution.find(params[:id])
  end

  def authorize_owner!
    unless @contribution.user == current_user
      redirect_to farm_path, alert: "Non autorisé"
    end
  end

  def contribution_params
    params.require(:farm_contribution).permit(:ingredient_id, :quantity)
  end
end
