class GuildStatistic < ApplicationRecord
  validates :stat_type, presence: true, uniqueness: true

  # Méthodes helper pour accéder aux différents types de stats
  def self.warcraft_logs_data
    find_by(stat_type: 'warcraft_logs')&.data || default_warcraft_logs_data
  end

  def self.raider_io_data
    find_by(stat_type: 'raider_io')&.data || []
  end

  def self.update_warcraft_logs(data)
    stat = find_or_initialize_by(stat_type: 'warcraft_logs')
    stat.data = data
    stat.save!
  end

  def self.update_raider_io(data)
    stat = find_or_initialize_by(stat_type: 'raider_io')
    stat.data = data
    stat.save!
  end

  private

  def self.default_warcraft_logs_data
    {
      'progression' => {
        'normal' => { 'killed' => 0, 'total' => 8 },
        'heroic' => { 'killed' => 0, 'total' => 8 },
        'mythic' => { 'killed' => 0, 'total' => 8 },
        'raid_name' => 'Manaforge Omega'
      },
      'recent_kills' => [],
      'death_stats' => []
    }
  end
end
