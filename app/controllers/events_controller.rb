class EventsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_event, only: [:show, :edit, :update, :destroy]

  def index
    @events = Event.all
  end

  def show
    @confirmed = @event.event_participations.where(status: "confirmed").includes(character: [:wow_class, :specialization], specialization: [])
    @tentative = @event.event_participations.where(status: "tentative").includes(character: [:wow_class, :specialization], specialization: [])
    @declined = @event.event_participations.where(status: "declined").includes(character: [:wow_class, :specialization], specialization: [])

    if user_signed_in?
      @my_characters = current_user.characters.includes(:wow_class, :specialization)
    end
  end

  def new
    @event = Event.new
    @event.start_time = params[:start_time] || Time.current + 1.hour
  end

  def create
    @event = current_user.events.build(event_params)

    if @event.save
      redirect_to @event, notice: "Événement créé !"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @event.update(event_params)
      redirect_to @event, notice: "Événement mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event.destroy
    redirect_to events_path, notice: "Événement supprimé."
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def event_params
    params.require(:event).permit(:title, :description, :start_time, :end_time, :event_type, :max_participants)
  end
end
