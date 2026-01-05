class CharactersController < ApplicationController
  before_action :authenticate_user!, except: [:index]

  def index
    @characters = Character.includes(:user, :wow_class, :specialization).order(created_at: :desc)
    @role_counts = Character.joins(:specialization).group("specializations.role").count
  end

  # Étape 1 : choix de la classe
  # Étape 2 : si wow_class_id présent, on affiche le form complet
  def new
    @character = Character.new

    if params[:wow_class_id]
      @wow_class = WowClass.find(params[:wow_class_id])
      @specializations = @wow_class.specializations
    else
      @wow_classes = WowClass.order(:name)
    end
  end

  def create
    @character = current_user.characters.build(character_params)

    if @character.save
      redirect_to characters_path, notice: "Perso ajouté !"
    else
      @wow_class = WowClass.find(params[:character][:wow_class_id])
      @specializations = @wow_class.specializations
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @character = current_user.characters.find(params[:id])
    @character.destroy
    redirect_to characters_path, notice: "Perso supprimé."
  end

  private

  def character_params
    params.require(:character).permit(:pseudo, :wow_class_id, :specialization_id)
  end
end
