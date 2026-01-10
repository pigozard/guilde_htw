class EventParticipationsController < ApplicationController
  before_action :authenticate_user!

  def create
    @event = Event.find(params[:event_id])
    @character = current_user.characters.find(params[:character_id])

    @participation = @event.event_participations.new(
      character: @character,
      specialization_id: params[:specialization_id],
      status: params[:status] || "confirmed"
    )

    if @participation.save
      redirect_to @event, notice: "Inscrit !"
    else
      redirect_to @event, alert: "Erreur"
    end
  end

  def update
    @event = Event.find(params[:event_id])
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
    @event = Event.find(params[:event_id])
    @participation = @event.event_participations.find(params[:id])

    if @participation.character.user == current_user
      @participation.destroy
      redirect_to @event, notice: "Inscription annulée"
    else
      redirect_to @event, alert: "Non autorisé"
    end
  end
end
