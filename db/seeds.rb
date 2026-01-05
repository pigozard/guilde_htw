puts "Cleaning database..."
Character.destroy_all
Specialization.destroy_all
WowClass.destroy_all

puts "Creating WoW classes and specs..."

CLASSES_DATA = {
  "Warrior" => [
    { name: "Arms", role: "dps" },
    { name: "Fury", role: "dps" },
    { name: "Protection", role: "tank" }
  ],
  "Paladin" => [
    { name: "Holy", role: "healer" },
    { name: "Protection", role: "tank" },
    { name: "Retribution", role: "dps" }
  ],
  "Hunter" => [
    { name: "Beast Mastery", role: "dps" },
    { name: "Marksmanship", role: "dps" },
    { name: "Survival", role: "dps" }
  ],
  "Rogue" => [
    { name: "Assassination", role: "dps" },
    { name: "Outlaw", role: "dps" },
    { name: "Subtlety", role: "dps" }
  ],
  "Priest" => [
    { name: "Discipline", role: "healer" },
    { name: "Holy", role: "healer" },
    { name: "Shadow", role: "dps" }
  ],
  "Shaman" => [
    { name: "Elemental", role: "dps" },
    { name: "Enhancement", role: "dps" },
    { name: "Restoration", role: "healer" }
  ],
  "Mage" => [
    { name: "Arcane", role: "dps" },
    { name: "Fire", role: "dps" },
    { name: "Frost", role: "dps" }
  ],
  "Warlock" => [
    { name: "Affliction", role: "dps" },
    { name: "Demonology", role: "dps" },
    { name: "Destruction", role: "dps" }
  ],
  "Monk" => [
    { name: "Brewmaster", role: "tank" },
    { name: "Mistweaver", role: "healer" },
    { name: "Windwalker", role: "dps" }
  ],
  "Druid" => [
    { name: "Balance", role: "dps" },
    { name: "Feral", role: "dps" },
    { name: "Guardian", role: "tank" },
    { name: "Restoration", role: "healer" }
  ],
  "Demon Hunter" => [
    { name: "Havoc", role: "dps" },
    { name: "Vengeance", role: "tank" }
  ],
  "Death Knight" => [
    { name: "Blood", role: "tank" },
    { name: "Frost", role: "dps" },
    { name: "Unholy", role: "dps" }
  ],
  "Evoker" => [
    { name: "Devastation", role: "dps" },
    { name: "Preservation", role: "healer" },
    { name: "Augmentation", role: "dps" }
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
