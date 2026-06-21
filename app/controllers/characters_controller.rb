class CharactersController < ApplicationController
  before_action :authenticate_user!, except: [:index]
  before_action :set_wow_classes, only: [:new, :create]
  before_action :require_admin!, only: [:clear_roster]

  def index
    @characters = Character.roster
    @role_counts = Character.role_counts
    @flex_count = Character.flex_count
    @class_counts = Character.class_counts
  end

  def new
    @character = Character.new

    if params[:wow_class_id]
      @wow_class = WowClass.find(params[:wow_class_id])
      @specializations = @wow_class.specializations
    elsif params[:flex]
      @flex = true
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
      end
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @character = current_user.characters.find(params[:id])
    @character.destroy
    redirect_back fallback_location: characters_path, notice: "Perso supprimé."
  end

  def clear_roster
    Character.update_all(in_roster: false)
    redirect_to characters_path, notice: "Roster vidé. Les joueurs peuvent réactiver leur perso."
  end

  def reactivate
    @character = current_user.characters.find(params[:id])
    @character.update!(in_roster: true)
    redirect_to characters_path, notice: "#{@character.pseudo} a rejoint le roster !"
  end

  private

  def set_wow_classes
    @wow_classes ||= WowClass.order(:name)
  end

  def character_params
    params.require(:character).permit(:pseudo, :wow_class_id, :specialization_id)
  end
end
