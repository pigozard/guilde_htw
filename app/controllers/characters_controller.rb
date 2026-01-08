class CharactersController < ApplicationController
  before_action :authenticate_user!, except: [:index]

  def index
    @characters = Character.includes(:user, :wow_class, :specialization).order(created_at: :desc)
    @role_counts = Character.joins(:specialization).group("specializations.role").count
    @flex_count = Character.where(specialization_id: nil).count
  end

  def new
    @character = Character.new

    if params[:wow_class_id]
      @wow_class = WowClass.find(params[:wow_class_id])
      @specializations = @wow_class.specializations
    elsif params[:flex]
      @flex = true
    else
      @wow_classes = WowClass.order(:name)
    end
  end

  def create
    @character = current_user.characters.build(character_params)

    if @character.save
      redirect_to characters_path, notice: "Perso ajouté !"
    else
      if params[:character][:wow_class_id].present?
        @wow_class = WowClass.find(params[:character][:wow_class_id])
        @specializations = @wow_class.specializations
      elsif @character.wow_class_id.nil?
        @flex = true
      else
        @wow_classes = WowClass.order(:name)
      end
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
