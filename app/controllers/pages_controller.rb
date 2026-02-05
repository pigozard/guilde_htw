class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]

  def home
    # Stats de guilde
    @members_count = User.count
    @characters_count = Character.permanent.count

    # Composition roster
    @tank_count = Character.permanent.joins(:specialization).where(specializations: { role: 'Tank' }).count
    @healer_count = Character.permanent.joins(:specialization).where(specializations: { role: 'Healer' }).count
    @dps_count = Character.permanent.joins(:specialization).where(specializations: { role: 'DPS' }).count

    # Prochain event
    @next_event = Event.where('start_time >= ?', DateTime.now).order(:start_time).first
    @next_event_participants = @next_event&.event_participations&.count || 0

    # Events cette semaine
    @events_this_week_count = Event.where(start_time: DateTime.now.beginning_of_week..DateTime.now.end_of_week).count

    # Activité récente
    @recent_participations = EventParticipation.includes(character: [:user, :wow_class, :specialization], event: []).order(created_at: :desc).limit(3)
    @recent_characters = Character.permanent.includes(:user, :wow_class, :specialization).order(created_at: :desc).limit(3)
    @recent_contributions = FarmContribution.includes(:user, :ingredient).order(created_at: :desc).limit(3)

    # WARCRAFT LOGS - Progression complète + Deaths
    fetch_warcraft_logs_data

    # RAIDER.IO - Top M+
    fetch_raider_io_data
  end

  private

  def fetch_warcraft_logs_data
    warcraftlogs = WarcraftLogsService.new
    data = warcraftlogs.guild_data

    @warcraftlogs_progression = data[:progression]
    @warcraftlogs_recent_kills = data[:recent_kills]
    @warcraftlogs_death_stats = data[:death_stats]
  rescue => e
    Rails.logger.error "Failed to fetch Warcraft Logs: #{e.message}"
    fallback_warcraftlogs_data
  end

  def fetch_raider_io_data
    raiderio = RaiderIoService.new
    @raiderio_top_players = raiderio.top_mythic_plus_players
  rescue => e
    Rails.logger.error "Failed to fetch Raider.io: #{e.message}"
    @raiderio_top_players = []
  end

  def fallback_warcraftlogs_data
    @warcraftlogs_progression = {
      normal: { killed: 0, total: 8 },
      heroic: { killed: 0, total: 8 },
      mythic: { killed: 0, total: 8 },
      raid_name: "Nerub-ar Palace"
    }
    @warcraftlogs_recent_kills = []
    @warcraftlogs_death_stats = []
  end
end
