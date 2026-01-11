class EventParticipationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event

  def create
    if params[:temporary] == "true"
      # Créer un personnage temporaire
      character = current_user.characters.create!(
        pseudo: params[:pseudo],
        wow_class_id: params[:wow_class_id],
        specialization_id: params[:specialization_id],
        temporary: true
      )
      character_id = character.id
    else
      character_id = params[:character_id]
    end

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
    @participation = @event.event_participations.find(params[:id])

    if @participation.character.user == current_user
      @participation.update(
        status: params[:status],
        specialization_id: params[:specialization_id]
      )
      redirect_to @event, notice: "Mis à jour !"
    else
      redirect_to @event, alert: "Non autorisé"
    end
  end

  def destroy
    @participation = @event.event_participations.find(params[:id])

    if @participation.character.user == current_user
      @participation.destroy
      redirect_to @event, notice: "Inscription annulée"
    else
      redirect_to @event, alert: "Non autorisé"
    end
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end
end
