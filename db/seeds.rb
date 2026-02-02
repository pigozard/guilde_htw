
# OU plus sûr :
Character.destroy_all unless Rails.env.production?


puts "Cleaning database..."
Character.destroy_all
Specialization.destroy_all
WowClass.destroy_all

puts "Creating WoW classes and specs..."

CLASSES_DATA = {
  "Warrior" => [
    { name: "Arms", role: "dps_cac" },
    { name: "Fury", role: "dps_cac" },
    { name: "Protection", role: "tank" }
  ],
  "Paladin" => [
    { name: "Holy", role: "healer" },
    { name: "Protection", role: "tank" },
    { name: "Retribution", role: "dps_cac" }
  ],
  "Hunter" => [
    { name: "Beast Mastery", role: "dps_caster" },
    { name: "Marksmanship", role: "dps_caster" },
    { name: "Survival", role: "dps_cac" }
  ],
  "Rogue" => [
    { name: "Assassination", role: "dps_cac" },
    { name: "Outlaw", role: "dps_cac" },
    { name: "Subtlety", role: "dps_cac" }
  ],
  "Priest" => [
    { name: "Discipline", role: "healer" },
    { name: "Holy", role: "healer" },
    { name: "Shadow", role: "dps_caster" }
  ],
  "Shaman" => [
    { name: "Elemental", role: "dps_caster" },
    { name: "Enhancement", role: "dps_cac" },
    { name: "Restoration", role: "healer" }
  ],
  "Mage" => [
    { name: "Arcane", role: "dps_caster" },
    { name: "Fire", role: "dps_caster" },
    { name: "Frost", role: "dps_caster" }
  ],
  "Warlock" => [
    { name: "Affliction", role: "dps_caster" },
    { name: "Demonology", role: "dps_caster" },
    { name: "Destruction", role: "dps_caster" }
  ],
  "Monk" => [
    { name: "Brewmaster", role: "tank" },
    { name: "Mistweaver", role: "healer" },
    { name: "Windwalker", role: "dps_cac" }
  ],
  "Druid" => [
    { name: "Balance", role: "dps_caster" },
    { name: "Feral", role: "dps_cac" },
    { name: "Guardian", role: "tank" },
    { name: "Restoration", role: "healer" }
  ],
  "Demon Hunter" => [
    { name: "Havoc", role: "dps_cac" },
    { name: "Vengeance", role: "tank" },
    { name: "Devoureur", role: "dps_caster" }
  ],
  "Death Knight" => [
    { name: "Blood", role: "tank" },
    { name: "Frost", role: "dps_cac" },
    { name: "Unholy", role: "dps_cac" }
  ],
  "Evoker" => [
    { name: "Devastation", role: "dps_caster" },
    { name: "Preservation", role: "healer" },
    { name: "Augmentation", role: "dps_caster" }
  ]
}

CLASSES_DATA.each do |class_name, specs|
  wow_class = WowClass.create!(name: class_name)
  specs.each do |spec|
    wow_class.specializations.create!(name: spec[:name], role: spec[:role])
  end
  puts "  Created #{class_name} with #{specs.count} specs"
end

puts "Done! Created #{WowClass.count} classes and #{Specialization.count} specs."

# Seed des expansions WoW
puts "🌟 Création des expansions..."

expansions_data = [
  { name: "Classic", code: "classic", slug: "classic", order_index: 0 },
  { name: "The Burning Crusade", code: "tbc", slug: "the-burning-crusade", order_index: 1 },
  { name: "Wrath of the Lich King", code: "wotlk", slug: "wrath-of-the-lich-king", order_index: 2 },
  { name: "Cataclysm", code: "cata", slug: "cataclysm", order_index: 3 },
  { name: "Mists of Pandaria", code: "mop", slug: "mists-of-pandaria", order_index: 4 },
  { name: "Warlords of Draenor", code: "wod", slug: "warlords-of-draenor", order_index: 5 },
  { name: "Legion", code: "legion", slug: "legion", order_index: 6 },
  { name: "Battle for Azeroth", code: "bfa", slug: "battle-for-azeroth", order_index: 7 },
  { name: "Shadowlands", code: "sl", slug: "shadowlands", order_index: 8 },
  { name: "Dragonflight", code: "df", slug: "dragonflight", order_index: 9 },
  { name: "The War Within", code: "tww", slug: "the-war-within", order_index: 10 }
]

expansions_data.each do |exp_data|
  expansion = Expansion.find_or_create_by(code: exp_data[:code]) do |e|
    e.name = exp_data[:name]
    e.slug = exp_data[:slug]
    e.order_index = exp_data[:order_index]
  end
  puts "  ✅ #{expansion.name}"
end

puts "✨ #{Expansion.count} expansions créées !"
