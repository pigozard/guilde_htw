class EventsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_event, only: [:show, :edit, :update, :destroy]
  before_action :authorize_owner!, only: [:edit, :update, :destroy]

  def index
    @date = params[:start_date] ? Date.parse(params[:start_date]) : Date.today
    @events = Event.where(start_time: @date.beginning_of_month.beginning_of_week..@date.end_of_month.end_of_week)
  end

  def show
    @confirmed = @event.event_participations.where(status: "confirmed").includes(character: [:wow_class, :specialization], specialization: [])
    @tentative = @event.event_participations.where(status: "tentative").includes(character: [:wow_class, :specialization], specialization: [])
    @declined = @event.event_participations.where(status: "declined").includes(character: [:wow_class, :specialization], specialization: [])

    if user_signed_in?
      @my_characters = current_user.characters.with_class.includes(:wow_class, :specialization)
    end
  end

  def new
    @event = Event.new
  end

  def create
    @event = current_user.created_events.build(event_params)
    parse_start_time

    if @event.save
      redirect_to @event, notice: "Créé ! start_time=#{@event.start_time} | raw=#{params[:event][:start_date]} #{params[:event][:start_hour]}"
    else
      @start_date = params[:event][:start_date]
      @start_hour = params[:event][:start_hour]
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    parse_start_time

    if @event.update(event_params)
      redirect_to @event, notice: "Événement mis à jour."
    else
      @start_date = params[:event][:start_date]
      @start_hour = params[:event][:start_hour]
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

  def authorize_owner!
    unless @event.user == current_user
      redirect_to events_path, alert: "Non autorisé"
    end
  end

  def parse_start_time
    return unless params[:event][:start_date].present? && params[:event][:start_hour].present?
    @event.start_time = Time.zone.parse("#{params[:event][:start_date]} #{params[:event][:start_hour]}")
  end

  def event_params
    params.require(:event).permit(:title, :description, :end_time, :event_type, :max_participants)
  end
end
