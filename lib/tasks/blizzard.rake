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
  # NETTOYAGE BASÉ SUR LA STRUCTURE EXCEL
  # ============================================================================

  desc "Nettoyage complet basé sur la structure Excel"
  task excel_clean: :environment do
    puts "📊 Nettoyage basé sur la structure Excel..."

    # Récupérer les expansions
    classic = Expansion.find_by(code: 'classic')
    tbc = Expansion.find_by(code: 'tbc')
    wotlk = Expansion.find_by(code: 'wotlk')
    cata = Expansion.find_by(code: 'cata')
    mop = Expansion.find_by(code: 'mop')
    wod = Expansion.find_by(code: 'wod')
    legion = Expansion.find_by(code: 'legion')
    bfa = Expansion.find_by(code: 'bfa')
    sl = Expansion.find_by(code: 'sl')
    df = Expansion.find_by(code: 'df')
    tww = Expansion.find_by(code: 'tww')

    total_moved = 0
    total_tagged = 0

    # ========================================================================
    # CLASSIC - Zones spécifiques
    # ========================================================================
    puts "\n🔵 Nettoyage CLASSIC"

    if classic
      classic_zones = [
        # Quêtes Classic
        "Désolace", "Tornades du Nord", "Serres-Rocheuses", "Marécage d'Âprefange",
        "Tornades du Sud", "Azshara", "Gangrebois", "Sillithus", "Tanaris",
        "Mille Pointes", "Cratère d'Un'Goro", "Berceau de l'Hiver", "Orneval",
        "Féralas", "Hinterlands", "Maleterres", "Contreforts de Hautebrande",
        "Forêt des Pins Argentés", "Steppes Ardentes", "Marais des Chagrins",
        "Cap de Strangleronce", "Terres Foudroyées", "Gorge des Vents Brûlants",
        "Strangleronce",
        # Exploration Classic
        "Durotar", "Mulgore", "Teldrassil", "Dun Morogh", "Elwynn",
        "Tirisfal", "Royaumes de l'Est", "Kalimdor",
        # Raids Classic
        "Temple d'Ahn'Qiraj", "Repaire de l'Aile noire", "Cœur du Magma",
        "Repaire d'Onyxia"
      ]

      classic_count = 0
      classic_zones.each do |zone|
        achs = Achievement.where("name LIKE ? OR category LIKE ? OR subcategory LIKE ?",
                                "%#{zone}%", "%#{zone}%", "%#{zone}%")
                         .where.not(expansion_id: classic.id)
        count = achs.update_all(expansion_id: classic.id)
        classic_count += count
      end
      puts "  ✅ #{classic_count} achievements → Classic"
      total_moved += classic_count
    end

    # ========================================================================
    # THE BURNING CRUSADE
    # ========================================================================
    puts "\n🟢 Nettoyage THE BURNING CRUSADE"

    if tbc
      tbc_zones = [
        "Péninsule des Flammes infernales", "Marécage de Zangar", "Forêt de Terokkar",
        "Nagrand", "Tranchantes", "Raz de Néant", "Vallée d'Ombrelune",
        "Outreterre", "Karazhan", "Gruul", "Magtheridon", "Repaire du serpent",
        "Donjon de la Tempête", "Mont Hyjal", "Temple noir", "Caverne du sanctuaire",
        "Cryptes d'Auchenaï"
      ]

      tbc_count = 0
      tbc_zones.each do |zone|
        achs = Achievement.where("name LIKE ? OR category LIKE ? OR subcategory LIKE ?",
                                "%#{zone}%", "%#{zone}%", "%#{zone}%")
                         .where.not(expansion_id: tbc.id)
        count = achs.update_all(expansion_id: tbc.id)
        tbc_count += count
      end
      puts "  ✅ #{tbc_count} achievements → TBC"
      total_moved += tbc_count
    end

    # ========================================================================
    # WRATH OF THE LICH KING
    # ========================================================================
    puts "\n❄️ Nettoyage WRATH OF THE LICH KING"

    if wotlk
      wotlk_zones = [
        "Fjord Hurlant", "Toundra Boréale", "Désolation des dragons",
        "Grisonnes", "Zul'Drak", "Bassin de Sholazar", "Pic Foudroyé",
        "Couronne de glace", "Norfendre", "Naxxramas", "Ulduar",
        "Épreuve du croisé", "Citadelle de la Couronne", "Tournoi d'Argent",
        "Lich King"
      ]

      wotlk_count = 0
      wotlk_zones.each do |zone|
        achs = Achievement.where("name LIKE ? OR category LIKE ? OR subcategory LIKE ?",
                                "%#{zone}%", "%#{zone}%", "%#{zone}%")
                         .where.not(expansion_id: wotlk.id)
        count = achs.update_all(expansion_id: wotlk.id)
        wotlk_count += count
      end
      puts "  ✅ #{wotlk_count} achievements → WotLK"
      total_moved += wotlk_count
    end

    # ========================================================================
    # CATACLYSM
    # ========================================================================
    puts "\n🌋 Nettoyage CATACLYSM"

    if cata
      cata_zones = [
        "Vashj'ir", "Mont Hyjal", "Tréfonds", "Hautes Terres", "Crépuscule",
        "Uldum", "Cataclysm", "Descente de l'Aile noire", "Bastion",
        "Trône des quatre vents", "Âme-des-Dragons"
      ]

      cata_count = 0
      cata_zones.each do |zone|
        achs = Achievement.where("name LIKE ? OR category LIKE ? OR subcategory LIKE ?",
                                "%#{zone}%", "%#{zone}%", "%#{zone}%")
                         .where.not(expansion_id: cata.id)
        count = achs.update_all(expansion_id: cata.id)
        cata_count += count
      end
      puts "  ✅ #{cata_count} achievements → Cataclysm"
      total_moved += cata_count
    end

    # ========================================================================
    # TAGS SPÉCIAUX
    # ========================================================================

    # PvP
    puts "\n⚔️ Marquage PvP"
    pvp_keywords = [
      "Joueur contre Joueur", "PvP", "Arena", "Arène", "Battleground", "Champs de bataille",
      "Ashran", "A'shran", "Vallée d'Alterac", "Bassin Arathi", "Goulet des Chanteguerres",
      "L'île des Conquérants", "Pics-Jumeaux", "Bataille de Gilnéas", "Terrain d'entraînement",
      "Effort de guerre", "Gladiator", "Honneur", "Conquête"
    ]

    pvp_count = 0
    pvp_keywords.each do |keyword|
      achs = Achievement.where("category LIKE ? OR name LIKE ?", "%#{keyword}%", "%#{keyword}%")
                       .where(is_feat_of_strength: false)
                       .where(tags: nil)
      pvp_count += achs.update_all(tags: 'pvp')
    end
    puts "  ✅ #{pvp_count} PvP marqués"
    total_tagged += pvp_count

    # Métiers
    puts "\n🔨 Marquage Métiers"
    profession_keywords = [
      "Métier", "Profession", "Cuisine", "Cooking", "Pêche", "Fishing",
      "Premiers secours", "First Aid", "Archéologie", "Archaeology",
      "Alchimie", "Alchemy", "Forge", "Blacksmithing", "Enchantement", "Enchanting",
      "Ingénierie", "Engineering", "Herboristerie", "Herbalism", "Calligraphie", "Inscription",
      "Joaillerie", "Jewelcrafting", "Travail du cuir", "Leatherworking",
      "Minage", "Mining", "Dépeçage", "Skinning", "Couture", "Tailoring"
    ]

    profession_count = 0
    profession_keywords.each do |keyword|
      achs = Achievement.where("category LIKE ? OR name LIKE ?", "%#{keyword}%", "%#{keyword}%")
                       .where(is_feat_of_strength: false)
                       .where(tags: nil)
      profession_count += achs.update_all(tags: 'professions')
    end
    puts "  ✅ #{profession_count} Métiers marqués"
    total_tagged += profession_count

    # Mascottes
    puts "\n🐾 Marquage Mascottes"
    pet_keywords = ["Bataille de mascottes", "Pet Battle", "Bataille", "Mascotte"]

    pet_count = 0
    pet_keywords.each do |keyword|
      achs = Achievement.where("category LIKE ? OR category = ?", "%#{keyword}%", keyword)
                       .where(is_feat_of_strength: false)
                       .where(tags: nil)
      pet_count += achs.update_all(tags: 'pets')
    end
    puts "  ✅ #{pet_count} Mascottes marqués"
    total_tagged += pet_count

    # Événements
    puts "\n🎉 Marquage Événements"
    event_keywords = [
      "Sanssaint", "Jardin des nobles", "Célébration d'anniversaire", "Fête lunaire",
      "De l'amour dans l'air", "Voile d'hiver", "Solstice d'été", "Foire de Sombrelune",
      "Brewfest", "Noblegarden", "Children's Week", "Pilgrim's Bounty"
    ]

    event_count = 0
    event_keywords.each do |keyword|
      achs = Achievement.where("category LIKE ?", "%#{keyword}%")
                       .where(is_feat_of_strength: false)
                       .where(tags: nil)
      event_count += achs.update_all(tags: 'events')
    end
    puts "  ✅ #{event_count} Événements marqués"
    total_tagged += event_count

    # Collections
    puts "\n🎨 Marquage Collections"
    collection_keywords = ["Montures", "Collections", "Apparences", "Héritage", "Coffre à jouets", "Monnaies"]

    collection_count = 0
    collection_keywords.each do |keyword|
      achs = Achievement.where("category LIKE ?", "%#{keyword}%")
                       .where(is_feat_of_strength: false)
                       .where(tags: nil)
      collection_count += achs.update_all(tags: 'collections')
    end
    puts "  ✅ #{collection_count} Collections marqués"
    total_tagged += collection_count

    # Exploration
    puts "\n🗺️ Marquage Exploration"
    exploration_keywords = ["Vol dynamique", "Exploration", "Traque"]

    exploration_count = 0
    exploration_keywords.each do |keyword|
      achs = Achievement.where("category LIKE ?", "%#{keyword}%")
                       .where(is_feat_of_strength: false)
                       .where(tags: nil)
      exploration_count += achs.update_all(tags: 'exploration')
    end
    puts "  ✅ #{exploration_count} Exploration marqués"
    total_tagged += exploration_count

    # Général
    puts "\n📋 Marquage Général"
    general_keywords = ["Donjons et raids", "Personnages", "Personnage", "Niveau", "En extérieur"]

    general_count = 0
    general_keywords.each do |keyword|
      achs = Achievement.where(category: keyword)
                       .where(is_feat_of_strength: false)
                       .where(tags: nil)
      general_count += achs.update_all(tags: 'general')
    end
    puts "  ✅ #{general_count} Général marqués"
    total_tagged += general_count

    # Tours de force
    puts "\n🏆 Marquage Tours de force"
    feat_keywords = ["Feats of Strength", "Tours de force", "Hauts faits de gloire", "Promotions"]

    feat_count = 0
    feat_keywords.each do |keyword|
      achs = Achievement.where("category LIKE ?", "%#{keyword}%")
                       .where(is_feat_of_strength: [false, nil])
      feat_count += achs.update_all(is_feat_of_strength: true)
    end
    puts "  ✅ #{feat_count} Tours de force marqués"
    total_tagged += feat_count

    puts "\n✨ Nettoyage terminé !"
    puts "📊 Résumé :"
    puts "  - #{total_moved} achievements déplacés"
    puts "  - #{total_tagged} achievements tagués"

    puts "\n📚 Par extension :"
    Expansion.ordered.each do |exp|
      count = exp.achievements.normal.count
      puts "  - #{exp.name.ljust(25)} : #{count}" if count > 0
    end

    puts "\n🏷️ Par tag :"
    puts "  - Tours de force : #{Achievement.where(is_feat_of_strength: true).count}"
    puts "  - PvP : #{Achievement.pvp.count}"
    puts "  - Métiers : #{Achievement.professions.count}"
    puts "  - Mascottes : #{Achievement.pets.count}"
    puts "  - Collections : #{Achievement.where(tags: 'collections').count}"
    puts "  - Exploration : #{Achievement.where(tags: 'exploration').count}"
    puts "  - Événements : #{Achievement.events.count}"
    puts "  - Général : #{Achievement.where(tags: 'general').count}"
  end

  # ============================================================================
  # ANALYSE
  # ============================================================================

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

  desc "Exporter toutes les catégories dans un CSV pour tri manuel"
  task export_categories_csv: :environment do
    require 'csv'

    puts "📤 Export des catégories en CSV..."

    csv_path = Rails.root.join('tmp', 'achievements_categories.csv')

    CSV.open(csv_path, 'w', write_headers: true, headers: ['CATEGORIE', 'SOUS_CATEGORIE', 'NOMBRE', 'EXTENSION_ACTUELLE', 'EXTENSION_CORRECTE', 'TAG']) do |csv|

      # Grouper par catégorie + sous-catégorie
      Achievement.where(is_feat_of_strength: false)
                 .group(:category, :subcategory)
                 .count
                 .sort_by { |(cat, subcat), count| [cat || "ZZZ", subcat || "ZZZ"] }
                 .each do |(category, subcategory), count|

        # Trouver l'extension actuelle
        sample = Achievement.where(category: category, subcategory: subcategory).first
        current_expansion = sample&.expansion&.code || "aucune"

        csv << [
          category || "",
          subcategory || "",
          count,
          current_expansion,
          "", # À REMPLIR : classic, tbc, wotlk, cata, mop, wod, legion, bfa, sl, df, tww
          ""  # À REMPLIR : pvp, professions, events, collections, exploration, pets, general (ou vide)
        ]
      end
    end

    puts "✅ Fichier généré : #{csv_path}"
    puts "\n📋 Instructions :"
    puts "1. Ouvre tmp/achievements_categories.csv dans Excel"
    puts "2. Colonne EXTENSION_CORRECTE : classic, tbc, wotlk, cata, mop, wod, legion, bfa, sl, df, tww"
    puts "3. Colonne TAG : pvp, professions, events, collections, exploration, pets, general (ou vide)"
    puts "4. Sauvegarde le fichier"
    puts "5. Lance : rake blizzard:import_categories_csv"
  end
end
