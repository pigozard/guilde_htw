class ConsumableSelectionsController < ApplicationController
  before_action :authenticate_user!

  def create
    @selection = current_user.consumable_selections.build(selection_params)
    @selection.week = Date.current.beginning_of_week

    if @selection.save
      redirect_to farm_path, notice: "Consommable ajouté ! 🎉"
    else
      redirect_to farm_path, alert: "Erreur : #{@selection.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    @selection = current_user.consumable_selections.find(params[:id])
    @selection.destroy
    redirect_to farm_path, notice: "Consommable retiré."
  end

  private

  def selection_params
    params.require(:consumable_selection).permit(:consumable_id, :quantity)
  end
end
