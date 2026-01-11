
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
