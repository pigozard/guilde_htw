class EventParticipationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event
  before_action :set_participation, only: [:update, :destroy]
  before_action :authorize_participation!, only: [:update, :destroy]

  def create
    character_id = find_or_create_character_id

    @participation = @event.event_participations.build(
      character_id: character_id,
      specialization_id: params[:specialization_id],
      status: params[:status]
    )

    if @participation.save
      redirect_to @event, notice: "Inscrit !"
    else
      redirect_to @event, alert: "Erreur lors de l'inscription."
    end
  end

  def update
    @participation.update(
      status: params[:status],
      specialization_id: params[:specialization_id]
    )
    redirect_to @event, notice: "Mis à jour !"
  end

  def destroy
    @participation.destroy
    redirect_to @event, notice: "Inscription annulée"
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def set_participation
    @participation = @event.event_participations.find(params[:id])
  end

  def authorize_participation!
    unless @participation.character.user == current_user
      redirect_to @event, alert: "Non autorisé"
    end
  end

  def find_or_create_character_id
    if params[:temporary] == "true"
      character = current_user.characters.create!(
        pseudo: params[:pseudo],
        wow_class_id: params[:wow_class_id],
        specialization_id: params[:specialization_id],
        temporary: true
      )
      character.id
    else
      params[:character_id]
    end
  end
end
