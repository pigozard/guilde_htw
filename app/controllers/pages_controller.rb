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

    # WARCRAFT LOGS - Depuis la DB (instantané !)
    load_warcraft_logs_from_db

    # RAIDER.IO - Depuis la DB (instantané !)
    load_raider_io_from_db
  end

  private

  def load_warcraft_logs_from_db
    wcl_data = GuildStatistic.warcraft_logs_data

    @warcraftlogs_progression = wcl_data['progression'].deep_symbolize_keys
    @warcraftlogs_recent_kills = wcl_data['recent_kills'].map(&:deep_symbolize_keys)
    @warcraftlogs_death_stats = wcl_data['death_stats'].map(&:deep_symbolize_keys)
  rescue => e
    Rails.logger.error "Failed to load Warcraft Logs from DB: #{e.message}"
    fallback_warcraftlogs_data
  end

  def load_raider_io_from_db
    @raiderio_top_players = GuildStatistic.raider_io_data.map(&:deep_symbolize_keys)
  rescue => e
    Rails.logger.error "Failed to load Raider.io from DB: #{e.message}"
    @raiderio_top_players = []
  end

  def fallback_warcraftlogs_data
    @warcraftlogs_progression = {
      normal: { killed: 0, total: 8 },
      heroic: { killed: 0, total: 8 },
      mythic: { killed: 0, total: 8 },
      raid_name: "Manaforge Omega"
    }
    @warcraftlogs_recent_kills = []
    @warcraftlogs_death_stats = []
  end
end
