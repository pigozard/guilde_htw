class EventsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_event, only: [:show, :edit, :update, :destroy]

  def index
    @date = params[:start_date] ? Date.parse(params[:start_date]) : Date.today
    @events = Event.where(start_time: @date.beginning_of_month.beginning_of_week..@date.end_of_month.end_of_week)
  end

  def show
    @confirmed = @event.event_participations.where(status: "confirmed").includes(character: [:wow_class, :specialization], specialization: [])
    @tentative = @event.event_participations.where(status: "tentative").includes(character: [:wow_class, :specialization], specialization: [])
    @declined = @event.event_participations.where(status: "declined").includes(character: [:wow_class, :specialization], specialization: [])
    if user_signed_in?
      @my_characters = current_user.characters.includes(:wow_class, :specialization).reject { |c| c.wow_class.nil? || c.wow_class.name == "Flex" }

    end
  end

  def new
    @event = Event.new
    @event.start_time = params[:start_time] || Time.current + 1.hour
  end

  def create
    @event = current_user.events.build(event_params)

    # Combiner date + heure
    if params[:event][:start_date].present? && params[:event][:start_hour].present?
      @event.start_time = DateTime.parse("#{params[:event][:start_date]} #{params[:event][:start_hour]}")
    end

    if @event.save
      redirect_to @event, notice: "Événement créé !"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    # Combiner date + heure
    if params[:event][:start_date].present? && params[:event][:start_hour].present?
      @event.start_time = DateTime.parse("#{params[:event][:start_date]} #{params[:event][:start_hour]}")
    end

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
