class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]

  def home
    @members_count = User.count
    @characters_count = Character.permanent.count

    # Prochain event
    @next_event = Event.where('start_time >= ?', DateTime.now)
                      .order(:start_time)
                      .first
    @next_event_participants = @next_event&.event_participations&.count || 0

    # NOUVEAU : Activité récente
    @recent_participations = EventParticipation
                              .includes(character: [:user, :wow_class, :specialization], event: [])
                              .order(created_at: :desc)
                              .limit(3)

    @recent_characters = Character
                          .permanent
                          .includes(:user, :wow_class, :specialization)
                          .order(created_at: :desc)
                          .limit(3)

    @recent_contributions = FarmContribution
      .includes(:user, :ingredient)
      .order(created_at: :desc)
      .limit(3)
  end
end
