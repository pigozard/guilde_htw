# Seed pour le système de farm collaboratif
# Données basées sur The War Within (TWW)

puts "🧹 Nettoyage des données farm..."
FarmContribution.destroy_all
Recipe.destroy_all
Consumable.destroy_all
Ingredient.destroy_all

puts "🌿 Création des herbes de TWW..."

herbs = [
  { name: "Mycobloom", category: "herb", icon_name: "inv_10_herbalism_herb_color5" },
  { name: "Blessing Blossom", category: "herb", icon_name: "inv_10_herbalism_herb_color1" },
  { name: "Arathor's Spear", category: "herb", icon_name: "inv_10_herbalism_herb_color3" },
  { name: "Luredrop", category: "herb", icon_name: "inv_10_herbalism_herb_color4" },
  { name: "Orbinid", category: "herb", icon_name: "inv_10_herbalism_herb_color2" },
  { name: "Null Lotus", category: "herb", icon_name: "inv_10_herbalism_herb_special1" }
]

herbs_objects = {}
herbs.each do |herb_data|
  herb = Ingredient.create!(herb_data)
  herbs_objects[herb_data[:name]] = herb
  puts "  ✅ #{herb.name}"
end

puts "\n🧪 Création des consumables TWW..."

# FLASKS (durée 1h, persist through death)
consumables_data = [
  {
    name: "Flask of Tempered Versatility",
    category: "flask",
    expansion: "The War Within",
    icon_name: "inv_10_alchemy_bottle_shape1_red",
    ingredients: [
      { name: "Mycobloom", quantity: 3 },
      { name: "Luredrop", quantity: 2 },
      { name: "Blessing Blossom", quantity: 1 }
    ]
  },
  {
    name: "Flask of Tempered Mastery",
    category: "flask",
    expansion: "The War Within",
    icon_name: "inv_10_alchemy_bottle_shape1_blue",
    ingredients: [
      { name: "Mycobloom", quantity: 3 },
      { name: "Orbinid", quantity: 2 },
      { name: "Arathor's Spear", quantity: 1 }
    ]
  },
  {
    name: "Flask of Tempered Swiftness",
    category: "flask",
    expansion: "The War Within",
    icon_name: "inv_10_alchemy_bottle_shape1_green",
    ingredients: [
      { name: "Mycobloom", quantity: 3 },
      { name: "Blessing Blossom", quantity: 2 },
      { name: "Luredrop", quantity: 1 }
    ]
  },
  {
    name: "Flask of Saving Graces",
    category: "flask",
    expansion: "The War Within",
    icon_name: "inv_10_alchemy_bottle_shape1_yellow",
    ingredients: [
      { name: "Mycobloom", quantity: 3 },
      { name: "Arathor's Spear", quantity: 2 },
      { name: "Orbinid", quantity: 1 }
    ]
  },
  {
    name: "Flask of Alchemical Chaos",
    category: "flask",
    expansion: "The War Within",
    icon_name: "inv_10_alchemy_bottle_shape1_purple",
    ingredients: [
      { name: "Mycobloom", quantity: 4 },
      { name: "Null Lotus", quantity: 1 },
      { name: "Orbinid", quantity: 2 }
    ]
  },

  # POTIONS (combat potions, 1 min cooldown)
  {
    name: "Tempered Potion of Power",
    category: "potion",
    expansion: "The War Within",
    icon_name: "inv_10_alchemy_bottle_shape2_red",
    ingredients: [
      { name: "Mycobloom", quantity: 2 },
      { name: "Luredrop", quantity: 1 }
    ]
  },
  {
    name: "Potion of Unwavering Focus",
    category: "potion",
    expansion: "The War Within",
    icon_name: "inv_10_alchemy_bottle_shape2_blue",
    ingredients: [
      { name: "Blessing Blossom", quantity: 2 },
      { name: "Arathor's Spear", quantity: 1 }
    ]
  },
  {
    name: "Algarian Mana Potion",
    category: "potion",
    expansion: "The War Within",
    icon_name: "inv_10_alchemy_bottle_shape3_blue",
    ingredients: [
      { name: "Mycobloom", quantity: 2 },
      { name: "Orbinid", quantity: 1 }
    ]
  },

  # FOOD (30min buff)
  {
    name: "Feast of the Divine Day",
    category: "food",
    expansion: "The War Within",
    icon_name: "inv_cooking_100_feastofthewintersnight",
    ingredients: [
      { name: "Mycobloom", quantity: 5 },
      { name: "Blessing Blossom", quantity: 3 }
    ]
  },

  # AUGMENT RUNE
  {
    name: "Crystallized Augment Rune",
    category: "rune",
    expansion: "The War Within",
    icon_name: "inv_10_jewelcrafting_gem3_color1_cut",
    ingredients: [
      { name: "Null Lotus", quantity: 2 },
      { name: "Mycobloom", quantity: 5 },
      { name: "Orbinid", quantity: 3 }
    ]
  }
]

consumables_data.each do |cons_data|
  ingredients_data = cons_data.delete(:ingredients)

  consumable = Consumable.create!(cons_data)

  # Création des recettes (lien consumable <-> ingredients)
  ingredients_data.each do |ing_data|
    ingredient = herbs_objects[ing_data[:name]]
    Recipe.create!(
      consumable: consumable,
      ingredient: ingredient,
      quantity: ing_data[:quantity]
    )
  end

  puts "  ✅ #{consumable.name} (#{consumable.category})"
end

puts "\n📊 Résumé:"
puts "  - #{Ingredient.count} ingrédients créés"
puts "  - #{Consumable.count} consumables créés"
puts "  - #{Recipe.count} recettes créées"

puts "\n✨ Seeds farm terminés avec succès!"
puts "\n💡 Pour tester:"
puts "   rails console"
puts "   Consumable.first.ingredients"
puts "   Ingredient.first.consumables"
