class ConsumableSelectionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_selection, only: [:update, :destroy]
  before_action :authorize_owner!, only: [:update, :destroy]

  def create
    @selection = current_user.consumable_selections.find_or_initialize_by(
      consumable_id: params[:consumable_id],
      week: Date.current.beginning_of_week
    )

    @selection.quantity = (@selection.quantity || 0) + 1

    if @selection.save
      redirect_to farm_path, notice: "✅ Consommable ajouté à ta sélection !"
    else
      redirect_to farm_path, alert: "Erreur : #{@selection.errors.full_messages.join(', ')}"
    end
  end

  def update
    case params[:action_type]
    when 'increase'
      @selection.quantity += 1
      message = "Quantité augmentée !"
    when 'decrease'
      if @selection.quantity > 1
        @selection.quantity -= 1
        message = "Quantité diminuée !"
      else
        @selection.destroy
        redirect_to farm_path, notice: "Sélection supprimée (quantité = 0)"
        return
      end
    when 'set_quantity'
      new_quantity = params[:quantity].to_i
      if new_quantity >= 1
        @selection.quantity = new_quantity
        message = "Quantité mise à jour !"
      else
        @selection.destroy
        redirect_to farm_path, notice: "Sélection supprimée (quantité = 0)"
        return
      end
    end

    if @selection.save
      redirect_to farm_path, notice: message
    else
      redirect_to farm_path, alert: "Erreur"
    end
  end

  def destroy
    @selection.destroy
    redirect_to farm_path, notice: "Consommable retiré de ta sélection"
  end

  private

  def set_selection
    @selection = ConsumableSelection.find(params[:id])
  end

  def authorize_owner!
    unless @selection.user == current_user
      redirect_to farm_path, alert: "Non autorisé"
    end
  end
end
