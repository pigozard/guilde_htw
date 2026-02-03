namespace :blizzard do
  # ============================================================================
  # IMPORT DE DONNÉES
  # ============================================================================

  desc "Importer les consumables et ingrédients depuis l'API Blizzard"
  task import_consumables: :environment do
    expansion = ENV['EXPANSION'] || 'tww'

    puts "🚀 Import des consumables #{expansion.upcase}..."

    service = BlizzardApiService.new
    unless service.authenticate
      puts "❌ Échec de l'authentification"
      exit
    end

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

      sleep(0.2)
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

    # Import des recettes
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

  desc "Importer les achievements depuis l'API Blizzard par extension (fichier YAML)"
  task import_achievements: :environment do
    expansion_code = ENV['EXPANSION'] || 'tww'

    expansion = Expansion.find_by(code: expansion_code)
    unless expansion
      puts "❌ Extension '#{expansion_code}' introuvable"
      puts "Extensions disponibles : #{Expansion.pluck(:code).join(', ')}"
      exit
    end

    puts "🏆 Import des achievements pour #{expansion.name}..."

    service = BlizzardApiService.new
    unless service.authenticate
      puts "❌ Échec de l'authentification"
      exit
    end

    data_file = Rails.root.join('lib', 'tasks', "#{expansion_code}_achievements.yml")
    unless File.exist?(data_file)
      puts "❌ Fichier #{data_file} introuvable"
      exit
    end

    data = YAML.load_file(data_file)
    achievement_ids = data['achievement_ids'] || []

    if achievement_ids.empty?
      puts "⚠️ Aucun achievement ID dans le fichier"
      exit
    end

    puts "📥 Import de #{achievement_ids.count} achievements..."
    imported = 0
    skipped = 0

    achievement_ids.each do |ach_id|
      print "  ID #{ach_id}... "

      if Achievement.exists?(blizzard_id: ach_id)
        puts "⏭️ Déjà importé"
        skipped += 1
        next
      end

      ach_data = service.get_achievement(ach_id)
      if ach_data
        achievement = Achievement.new(
          blizzard_id: ach_id,
          name: ach_data['name'],
          description: ach_data['description'] || '',
          points: ach_data['points'] || 0,
          expansion: expansion
        )

        if ach_data['media'] && ach_data['media']['id']
          media_data = service.get_achievement_media(ach_data['media']['id'])
          if media_data && media_data['assets']
            icon_asset = media_data['assets'].find { |a| a['key'] == 'icon' }
            if icon_asset && icon_asset['value']
              icon_name = icon_asset['value'].split('/').last.gsub('.jpg', '')
              achievement.icon = icon_name
            end
          end
        end

        if achievement.save
          puts "✅ #{achievement.name}"
          imported += 1
        else
          puts "❌ #{achievement.errors.full_messages.join(', ')}"
        end
      else
        puts "⚠️ Introuvable"
      end

      sleep(0.2)
    end

    puts "\n✨ Import terminé !"
    puts "📊 Résumé :"
    puts "  - #{imported} nouveaux achievements importés"
    puts "  - #{skipped} achievements déjà existants"
  end

  desc "Importer TOUS les achievements depuis l'API Blizzard (import massif)"
  task import_all_achievements: :environment do
    puts "🏆 Import massif de TOUS les achievements WoW..."
    puts "⚠️  Cela peut prendre 20-30 minutes, soyez patient !\n\n"

    service = BlizzardApiService.new
    unless service.authenticate
      puts "❌ Échec de l'authentification"
      exit
    end

    puts "📥 Récupération des catégories d'achievements..."
    categories_data = service.get_achievement_categories

    unless categories_data && categories_data['categories']
      puts "❌ Impossible de récupérer les catégories"
      exit
    end

    total_imported = 0
    total_skipped = 0
    total_categories = categories_data['categories'].count

    categories_data['categories'].each_with_index do |category, index|
      category_id = category['id']
      category_name = category['name']

      puts "\n[#{index + 1}/#{total_categories}] 📂 Catégorie : #{category_name}"

      category_details = service.get_achievement_category(category_id)
      next unless category_details

      expansion = determine_expansion_from_category(category_name)
      next unless expansion

      if category_details['achievements']
        category_details['achievements'].each do |ach_data|
          ach_id = ach_data['id']

          if Achievement.exists?(blizzard_id: ach_id)
            total_skipped += 1
            print "."
            next
          end

          full_ach_data = service.get_achievement(ach_id)
          next unless full_ach_data

          achievement = Achievement.new(
            blizzard_id: ach_id,
            name: full_ach_data['name'],
            description: full_ach_data['description'] || '',
            points: full_ach_data['points'] || 0,
            expansion: expansion,
            category: category_name,
            subcategory: category_details['parent_category'] ? category_details['parent_category']['name'] : nil
          )

          if full_ach_data['media'] && full_ach_data['media']['id']
            media_data = service.get_achievement_media(full_ach_data['media']['id'])
            if media_data && media_data['assets']
              icon_asset = media_data['assets'].find { |a| a['key'] == 'icon' }
              if icon_asset && icon_asset['value']
                icon_name = icon_asset['value'].split('/').last.gsub('.jpg', '')
                achievement.icon = icon_name
              end
            end
          end

          if achievement.save
            total_imported += 1
            print "✓"
          else
            print "✗"
          end

          sleep(0.1)
        end
      end

      puts " (#{category_details['achievements']&.count || 0} achievements)"
    end

    puts "\n\n✨ Import terminé !"
    puts "📊 Résumé :"
    puts "  - #{total_imported} nouveaux achievements importés"
    puts "  - #{total_skipped} achievements déjà existants"
    puts "  - #{Achievement.count} achievements totaux en BDD"
  end

  # ============================================================================
  # RÉORGANISATION
  # ============================================================================

  desc "Remettre à zéro tous les achievements (extension + tags)"
  task reset_achievements: :environment do
    puts "🔄 Remise à zéro des achievements..."

    total = Achievement.count

    puts "\n⚠️  ATTENTION : Vous allez réinitialiser #{total} achievements !"
    puts "Les achievements resteront en BDD mais :"
    puts "  - Toutes les extensions seront mises sur Classic par défaut"
    puts "  - Tous les tags seront supprimés"
    puts "  - Les catégories/sous-catégories seront conservées"
    puts "\nContinuer ? (y/n)"

    response = STDIN.gets.chomp

    if response.downcase == 'y'
      classic = Expansion.find_by(code: 'classic')

      # Réinitialiser
      Achievement.update_all(
        expansion_id: classic&.id,
        tags: nil,
        is_feat_of_strength: false
      )

      puts "\n✅ #{total} achievements réinitialisés !"
      puts "📊 Tous les achievements sont maintenant dans Classic sans tags"
      puts "🚀 Tu peux maintenant lancer : rake blizzard:reorganize_from_blizzard_api"
    else
      puts "❌ Annulé"
    end
  end

  desc "Réorganiser les achievements en utilisant l'API Blizzard (structure officielle)"
  task reorganize_from_blizzard_api: :environment do
    puts "🏆 Réorganisation via l'API Blizzard..."

    service = BlizzardApiService.new
    unless service.authenticate
      puts "❌ Échec de l'authentification"
      exit
    end

    puts "📥 Récupération de la structure des catégories..."
    categories_data = service.get_achievement_categories

    unless categories_data && categories_data['categories']
      puts "❌ Impossible de récupérer les catégories"
      exit
    end

    total_moved = 0
    total_tagged = 0

    # Mapping des catégories vers extensions
    expansion_keywords = {
      'classic' => ['Classic', 'Royaumes de l\'Est', 'Kalimdor'],
      'tbc' => ['Burning Crusade', 'Outreterre', 'Outland'],
      'wotlk' => ['Lich King', 'Norfendre', 'Northrend', 'Wrath'],
      'cata' => ['Cataclysm', 'Cataclysme', 'Vashj\'ir', 'Mont Hyjal', 'Tréfonds', 'Uldum'],
      'mop' => ['Mists of Pandaria', 'Pandarie', 'Pandaria'],
      'wod' => ['Warlords of Draenor', 'Draenor'],
      'legion' => ['Legion'],
      'bfa' => ['Battle for Azeroth', 'Kul Tiras', 'Zandalar'],
      'sl' => ['Shadowlands', 'Ombreterre', 'Maldraxxus', 'Revendreth', 'Bastion', 'Ardenweald'],
      'df' => ['Dragonflight', 'Îles aux Dragons', 'Dragon Isles'],
      'tww' => ['War Within', 'The War Within']
    }

    # Tags spéciaux
    tag_keywords = {
      'pvp' => ['Player vs. Player', 'PvP', 'Arena', 'Arène', 'Battleground', 'Champs de bataille'],
      'professions' => ['Profession', 'Métier', 'Cooking', 'Cuisine', 'Fishing', 'Pêche'],
      'pets' => ['Pet Battle', 'Bataille de mascottes', 'Mascotte'],
      'events' => ['World Event', 'Événement', 'Holiday', 'Fête'],
      'collections' => ['Collection', 'Mount', 'Monture', 'Apparence', 'Héritage'],
      'exploration' => ['Exploration', 'Vol dynamique', 'Dragonriding']
    }

    puts "\n📂 Analyse des catégories..."

    categories_data['categories'].each do |category|
      category_id = category['id']
      category_name = category['name']

      # Récupérer les détails de la catégorie
      category_details = service.get_achievement_category(category_id)
      next unless category_details
      next unless category_details['achievements']

      achievement_ids = category_details['achievements'].map { |a| a['id'] }

      # Vérifier si c'est un tag spécial
      tag_assigned = nil
      tag_keywords.each do |tag, keywords|
        if keywords.any? { |keyword| category_name.include?(keyword) }
          tag_assigned = tag
          break
        end
      end

      if tag_assigned
        # C'est une catégorie spéciale
        tagged = Achievement.where(blizzard_id: achievement_ids)
                           .where(tags: nil)
                           .update_all(tags: tag_assigned)

        if tagged > 0
          puts "  🏷️ #{category_name} → TAG: #{tag_assigned} (#{tagged} achievements)"
          total_tagged += tagged
        end
      else
        # C'est une catégorie d'extension
        expansion_code = nil
        expansion_keywords.each do |exp_code, keywords|
          if keywords.any? { |keyword| category_name.include?(keyword) }
            expansion_code = exp_code
            break
          end
        end

        if expansion_code
          expansion = Expansion.find_by(code: expansion_code)
          if expansion
            moved = Achievement.where(blizzard_id: achievement_ids)
                             .where.not(expansion_id: expansion.id)
                             .update_all(expansion_id: expansion.id)

            if moved > 0
              puts "  ✅ #{category_name} → #{expansion.name} (#{moved} achievements)"
              total_moved += moved
            end
          end
        end
      end

      sleep(0.1)
    end

    # Tours de force
    puts "\n🏆 Marquage des Tours de force..."
    feat_count = Achievement.where("category LIKE ?", "%Feats of Strength%")
                           .or(Achievement.where("category LIKE ?", "%Tours de force%"))
                           .update_all(is_feat_of_strength: true)
    puts "  ✅ #{feat_count} Tours de force marqués"

    puts "\n✨ Réorganisation terminée !"
    puts "📊 Total achievements déplacés : #{total_moved}"
    puts "📊 Total achievements tagués : #{total_tagged}"

    puts "\n📚 Par extension :"
    Expansion.ordered.each do |exp|
      count = exp.achievements.normal.count
      puts "  - #{exp.name.ljust(25)} : #{count}" if count > 0
    end

    puts "\n🏷️ Par tag :"
    puts "  - Tours de force : #{Achievement.where(is_feat_of_strength: true).count}"
    puts "  - PvP : #{Achievement.where(tags: 'pvp').count}"
    puts "  - Métiers : #{Achievement.where(tags: 'professions').count}"
    puts "  - Mascottes : #{Achievement.where(tags: 'pets').count}"
    puts "  - Collections : #{Achievement.where(tags: 'collections').count}"
    puts "  - Exploration : #{Achievement.where(tags: 'exploration').count}"
    puts "  - Événements : #{Achievement.where(tags: 'events').count}"
  end

  desc "Analyser les catégories restantes dans Classic"
  task analyze_classic: :environment do
    puts "🔍 Analyse des catégories dans Classic..."

    classic = Expansion.find_by(code: 'classic')
    return unless classic

    categories = classic.achievements.normal
                        .where.not(category: nil)
                        .group(:category)
                        .count
                        .sort_by { |k, v| -v }

    puts "\n📊 Top 30 catégories dans Classic :"
    categories.first(30).each do |category, count|
      puts "  #{count.to_s.rjust(4)} | #{category}"
    end

    puts "\n💡 Total achievements 'normaux' dans Classic : #{classic.achievements.normal.count}"
  end

  # ============================================================================
  # MÉTHODES HELPER
  # ============================================================================

  def determine_expansion_from_category(category_name)
    mapping = {
      'War Within' => 'tww',
      'Dragonflight' => 'df',
      'Shadowlands' => 'sl',
      'Battle for Azeroth' => 'bfa',
      'Legion' => 'legion',
      'Warlords of Draenor' => 'wod',
      'Mists of Pandaria' => 'mop',
      'Cataclysm' => 'cata',
      'Wrath of the Lich King' => 'wotlk',
      'Burning Crusade' => 'tbc',
      'Classic' => 'classic'
    }

    mapping.each do |key, code|
      return Expansion.find_by(code: code) if category_name.include?(key)
    end

    Expansion.find_by(code: 'classic')
  end
  desc "Diagnostiquer un achievement spécifique pour un personnage"
  task diagnose_achievement: :environment do
    character_name = ENV['CHARACTER'] || 'inbox'
    realm = ENV['REALM'] || 'dalaran'
    region = ENV['REGION'] || 'eu'
    achievement_id = ENV['ACHIEVEMENT_ID'] || '2046' # Le croisé ardent

    puts "🔍 Diagnostic pour #{character_name}-#{realm} (#{region.upcase})"
    puts "🎯 Achievement ID: #{achievement_id}"

    service = BlizzardApiService.new(region: region)

    unless service.authenticate
      puts "❌ Échec authentification"
      exit
    end

    # 1. Vérifier si l'achievement existe en BDD
    ach = Achievement.find_by(blizzard_id: achievement_id)
    if ach
      puts "\n✅ Achievement en BDD:"
      puts "  - Nom: #{ach.name}"
      puts "  - Extension: #{ach.expansion&.name}"
      puts "  - Catégorie: #{ach.category}"
    else
      puts "\n❌ Achievement NOT found en BDD"
    end

    # 2. Récupérer les achievements du personnage via API
    puts "\n📥 Récupération des achievements du personnage..."
    data = service.get_character_achievements(realm, character_name)

    if data.nil?
      puts "❌ Personnage introuvable"
      exit
    end

    # 3. Extraire tous les IDs
    completed_ids = []
    if data['achievements']
      data['achievements'].each do |achievement_data|
        completed_ids << achievement_data['id'] if achievement_data['id']

        if achievement_data['achievements']
          achievement_data['achievements'].each do |sub_ach|
            completed_ids << sub_ach['id'] if sub_ach['id']
          end
        end
      end
    end

    completed_ids.uniq!

    puts "\n📊 Total achievements retournés par l'API: #{completed_ids.count}"

    # 4. Vérifier si notre achievement est dedans
    if completed_ids.include?(achievement_id.to_i)
      puts "\n✅ L'achievement #{achievement_id} EST dans les données API"
    else
      puts "\n❌ L'achievement #{achievement_id} N'EST PAS dans les données API"
      puts "\n💡 Possible raison: Achievement account-wide pas retourné par l'API character"
    end

    # 5. Vérifier la dernière synchro en BDD
    sync = User.find_by(email: 'ton_email@example.com')&.user_achievement_syncs&.last
    if sync
      puts "\n📋 Dernière synchro en BDD:"
      puts "  - Personnage: #{sync.character_name}"
      puts "  - Serveur: #{sync.realm}"
      puts "  - Date: #{sync.synced_at}"
      puts "  - Total achievements: #{sync.achievement_ids.count}"

      if sync.achievement_ids.include?(achievement_id.to_i)
        puts "  - ✅ L'achievement #{achievement_id} est dans la synchro"
      else
        puts "  - ❌ L'achievement #{achievement_id} n'est PAS dans la synchro"
      end
    end

    puts "\n🔧 Pour tester un autre achievement:"
    puts "ACHIEVEMENT_ID=12345 CHARACTER=inbox REALM=dalaran REGION=eu rake blizzard:diagnose_achievement"
  end

  desc "Supprimer les achievements en double (garder le plus grand ID Blizzard)"
  task remove_duplicate_achievements: :environment do
    puts "🧹 Nettoyage des achievements en double..."

    total_deleted = 0

    # Trouver tous les noms qui apparaissent plusieurs fois
    duplicate_names = Achievement.select(:name)
                                 .group(:name)
                                 .having('count(*) > 1')
                                 .count
                                 .keys

    puts "📊 Trouvé #{duplicate_names.count} noms en double"

    duplicate_names.each do |name|
      achievements = Achievement.where(name: name).order(:blizzard_id)

      if achievements.count > 1
        # Garder celui avec le plus grand blizzard_id
        to_keep = achievements.last
        to_delete = achievements[0..-2]

        puts "\n📋 '#{name}' (#{achievements.count} doublons)"
        puts "  ✅ Garde : ID #{to_keep.blizzard_id} (#{to_keep.expansion&.name})"

        to_delete.each do |ach|
          puts "  ❌ Supprime : ID #{ach.blizzard_id} (#{ach.expansion&.name})"
          ach.destroy
          total_deleted += 1
        end
      end
    end

    puts "\n✨ Nettoyage terminé !"
    puts "📊 #{total_deleted} achievements supprimés"
    puts "💾 #{Achievement.count} achievements restants"
  end

  desc "Supprimer TOUS les achievements pour réimport propre"
task delete_all_achievements: :environment do
  puts "⚠️  ATTENTION : Suppression TOTALE de tous les achievements !"
  puts "Continuer ? (y/n)"

  response = STDIN.gets.chomp

  if response.downcase == 'y'
    count = Achievement.count
    Achievement.destroy_all
    UserAchievementSync.destroy_all

    puts "✅ #{count} achievements supprimés"
    puts "✅ Toutes les synchros utilisateur supprimées"
    puts "🚀 Prêt pour le réimport propre"
  else
    puts "❌ Annulé"
  end
end
desc "Réimport COMPLET avec mapping correct depuis l'API Blizzard"
task reimport_achievements_clean: :environment do
  puts "🏆 Réimport PROPRE de tous les achievements..."

  service = BlizzardApiService.new
  unless service.authenticate
    puts "❌ Échec authentification"
    exit
  end

  puts "📥 Récupération des catégories..."
  categories_data = service.get_achievement_categories

  unless categories_data && categories_data['categories']
    puts "❌ Erreur API"
    exit
  end

  # Mapping COMPLET et PRÉCIS
  expansion_mapping = {
    'tww' => ['War Within', 'The War Within'],
    'df' => ['Dragonflight', 'Dragon Isles', 'Îles aux Dragons'],
    'sl' => ['Shadowlands', 'Ombreterre', 'Maldraxxus', 'Revendreth', 'Bastion',
             'Ardenweald', 'Gouffres', 'Sanctums', 'Tourment'],
    'bfa' => ['Battle for Azeroth', 'Kul Tiras', 'Zandalar', 'Vision', 'N\'Zoth'],
    'legion' => ['Legion', 'Îles Brisées', 'Broken Isles'],
    'wod' => ['Warlords of Draenor', 'Draenor', 'Fief', 'Garrison'],
    'mop' => ['Mists of Pandaria', 'Pandarie', 'Pandaria'],
    'cata' => ['Cataclysm', 'Cataclysme', 'Vashj\'ir', 'Mont Hyjal', 'Tréfonds',
               'Uldum', 'Profondeurs'],
    'wotlk' => ['Lich King', 'Norfendre', 'Northrend', 'Wrath', 'Tournoi d\'Argent'],
    'tbc' => ['Burning Crusade', 'Outreterre', 'Outland'],
    'classic' => ['Classic', 'Royaumes de l\'Est', 'Kalimdor']
  }

  # Tags spéciaux
  tag_mapping = {
    'pvp' => ['Player vs. Player', 'PvP', 'Arena', 'Battleground', 'Bataille',
              'Champs de bataille', 'En extérieur', 'Ashran', 'Alterac'],
    'professions' => ['Profession', 'Métier', 'Cooking', 'Cuisine', 'Fishing',
                      'Pêche', 'Archéologie', 'Archaeology', 'Alchemy', 'Forge'],
    'events' => ['World Event', 'Événement', 'Holiday', 'Fête', 'Foire de Sombrelune',
                 'Sanssaint', 'Solstice', 'Noblegarden'],
    'collections' => ['Collection', 'Mount', 'Monture', 'Apparence', 'Héritage',
                      'Coffre à jouets'],
    'pets' => ['Pet Battle', 'Mascotte', 'Bataille de mascottes'],
    'exploration' => ['Exploration', 'Vol dynamique', 'Dragonriding']
  }

  total_imported = 0

  categories_data['categories'].each_with_index do |category, index|
    category_id = category['id']
    category_name = category['name']

    puts "\n[#{index + 1}/#{categories_data['categories'].count}] 📂 #{category_name}"

    # Skip Feats of Strength
    if category_name.include?('Feats of Strength') || category_name.include?('Tours de force')
      puts "  ⏭️  Skipped (Feats of Strength)"
      next
    end

    category_details = service.get_achievement_category(category_id)
    next unless category_details && category_details['achievements']

    # Déterminer extension OU tag
    target_expansion = nil
    target_tag = nil

    # Vérifier d'abord les tags spéciaux
    tag_mapping.each do |tag, keywords|
      if keywords.any? { |kw| category_name.include?(kw) }
        target_tag = tag
        break
      end
    end

    # Si pas de tag, chercher l'extension
    unless target_tag
      expansion_mapping.each do |exp_code, keywords|
        if keywords.any? { |kw| category_name.include?(kw) }
          target_expansion = Expansion.find_by(code: exp_code)
          break
        end
      end
    end

    # Par défaut : Classic
    target_expansion ||= Expansion.find_by(code: 'classic') unless target_tag

    # Importer les achievements
    category_details['achievements'].each do |ach_data|
      ach_id = ach_data['id']

      full_ach_data = service.get_achievement(ach_id)
      next unless full_ach_data

      achievement = Achievement.new(
        blizzard_id: ach_id,
        name: full_ach_data['name'],
        description: full_ach_data['description'] || '',
        points: full_ach_data['points'] || 0,
        category: category_name,
        subcategory: category_details['parent_category'] ? category_details['parent_category']['name'] : nil
      )

      # Assigner extension ou tag
      if target_tag
        achievement.tags = target_tag
        achievement.expansion = Expansion.find_by(code: 'classic') # Fallback
      else
        achievement.expansion = target_expansion
      end

      # Récupérer icône
      if full_ach_data['media'] && full_ach_data['media']['id']
        media_data = service.get_achievement_media(full_ach_data['media']['id'])
        if media_data && media_data['assets']
          icon_asset = media_data['assets'].find { |a| a['key'] == 'icon' }
          if icon_asset && icon_asset['value']
            icon_name = icon_asset['value'].split('/').last.gsub('.jpg', '')
            achievement.icon = icon_name
          end
        end
      end

      if achievement.save
        total_imported += 1
        print "✓"
      else
        print "✗"
      end

      sleep(0.1)
    end

    puts " (#{category_details['achievements'].count} achievements)"
  end

  puts "\n\n✨ Réimport terminé !"
  puts "📊 #{total_imported} achievements importés"

  puts "\n📚 Par extension :"
  Expansion.ordered.each do |exp|
    count = exp.achievements.where(is_feat_of_strength: false).count
    puts "  - #{exp.name.ljust(25)} : #{count}" if count > 0
  end
end
end
