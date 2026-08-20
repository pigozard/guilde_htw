class GuildStatistic < ApplicationRecord
  validates :stat_type, presence: true, uniqueness: true

  def self.warcraft_logs_data
    data = find_by(stat_type: 'warcraft_logs')&.data || default_warcraft_logs_data

    if data['recent_kills']
      data['recent_kills'].each do |kill|
        kill['date'] = Time.parse(kill['date']) if kill['date'].is_a?(String)
      end
    end

    data
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
        'The Venomous Abyss' => {
          'total'  => 8,
          'normal' => { 'killed' => 0, 'total' => 8 },
          'heroic' => { 'killed' => 0, 'total' => 8 },
          'mythic' => { 'killed' => 0, 'total' => 8 }
        },
        'The Tidebound Grotto' => {
          'total'  => 1,
          'normal' => { 'killed' => 0, 'total' => 1 },
          'heroic' => { 'killed' => 0, 'total' => 1 },
          'mythic' => { 'killed' => 0, 'total' => 1 }
        }
      },
      'recent_kills'       => [],
      'death_stats'        => [],
      'latest_report_code' => nil
    }
  end
end
