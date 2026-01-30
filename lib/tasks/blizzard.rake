namespace :blizzard do
  desc "Importer les consumables et ingrédients depuis l'API Blizzard"
  task import_consumables: :environment do
    expansion = ENV['EXPANSION'] || 'tww'

    puts "🚀 Import des consumables #{expansion.upcase}..."

    service = BlizzardApiService.new
    unless service.authenticate
      puts "❌ Échec de l'authentification"
      exit
    end

    # Charger les données depuis le fichier YAML
    data_file = Rails.root.join('lib', 'tasks', "#{expansion}_items.yml")
    unless File.exist?(data_file)
      puts "❌ Fichier #{data_file} introuvable"
      exit
    end

    data = YAML.load_file(data_file)

    # Import des ingrédients
    puts "\n📥 Import des ingrédients..."
    imported_ingredients = 0
    data['ingredients'].each do |blizzard_id, config|
      print "  ID #{blizzard_id}... "

      item_data = service.get_item(blizzard_id)
      if item_data
        ingredient = Ingredient.find_or_initialize_by(blizzard_id: blizzard_id)
        ingredient.name = item_data['name']
        ingredient.category = config['category']

        # Récupérer l'icône
        if item_data['media'] && item_data['media']['id']
          media_data = service.get_item_media(item_data['media']['id'])
          if media_data && media_data['assets']
            icon_asset = media_data['assets'].find { |a| a['key'] == 'icon' }
            if icon_asset && icon_asset['value']
              icon_name = icon_asset['value'].split('/').last.gsub('.jpg', '')
              ingredient.icon_name = icon_name
            end
          end
        end

        if ingredient.save
          puts "✅ #{ingredient.name}"
          imported_ingredients += 1
        else
          puts "❌ #{ingredient.errors.full_messages.join(', ')}"
        end
      else
        puts "⚠️ Introuvable"
      end

      sleep(0.2) # Rate limiting
    end

    # Import des consumables
    puts "\n📥 Import des consumables..."
    imported_consumables = 0
    data['consumables'].each do |blizzard_id, config|
      print "  ID #{blizzard_id}... "

      item_data = service.get_item(blizzard_id)
      if item_data
        consumable = Consumable.find_or_initialize_by(blizzard_id: blizzard_id)
        consumable.name = item_data['name']
        consumable.category = config['category']
        consumable.expansion = config['expansion']

        # Récupérer l'icône
        if item_data['media'] && item_data['media']['id']
          media_data = service.get_item_media(item_data['media']['id'])
          if media_data && media_data['assets']
            icon_asset = media_data['assets'].find { |a| a['key'] == 'icon' }
            if icon_asset && icon_asset['value']
              icon_name = icon_asset['value'].split('/').last.gsub('.jpg', '')
              consumable.icon_name = icon_name
            end
          end
        end

        if consumable.save
          puts "✅ #{consumable.name}"
          imported_consumables += 1
        else
          puts "❌ #{consumable.errors.full_messages.join(', ')}"
        end
      else
        puts "⚠️ Introuvable"
      end

      sleep(0.2)
    end

    # Import des recettes (si définies)
    if data['recipes']
      puts "\n📥 Import des recettes..."
      imported_recipes = 0
      data['recipes'].each do |consumable_blizzard_id, ingredients_list|
        consumable = Consumable.find_by(blizzard_id: consumable_blizzard_id)
        next unless consumable

        ingredients_list.each do |recipe_data|
          ingredient = Ingredient.find_by(blizzard_id: recipe_data['ingredient_id'])
          next unless ingredient

          recipe = Recipe.find_or_initialize_by(
            consumable: consumable,
            ingredient: ingredient
          )
          recipe.quantity = recipe_data['quantity']

          if recipe.save
            imported_recipes += 1
          end
        end
      end
      puts "  ✅ #{imported_recipes} recettes importées"
    end

    puts "\n✨ Import terminé !"
    puts "📊 Résumé :"
    puts "  - #{imported_ingredients} ingrédients importés"
    puts "  - #{imported_consumables} consumables importés"
    puts "  - #{Recipe.count} recettes totales"
  end
end
