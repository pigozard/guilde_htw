# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_02_03_205049) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "achievements", force: :cascade do |t|
    t.integer "blizzard_id", null: false
    t.string "name", null: false
    t.text "description"
    t.string "icon"
    t.integer "points", default: 0
    t.bigint "expansion_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "category"
    t.string "subcategory"
    t.string "tags"
    t.boolean "is_feat_of_strength", default: false
    t.integer "display_order", default: 0
    t.index ["blizzard_id"], name: "index_achievements_on_blizzard_id", unique: true
    t.index ["category"], name: "index_achievements_on_category"
    t.index ["display_order"], name: "index_achievements_on_display_order"
    t.index ["expansion_id"], name: "index_achievements_on_expansion_id"
    t.index ["is_feat_of_strength"], name: "index_achievements_on_is_feat_of_strength"
    t.index ["tags"], name: "index_achievements_on_tags"
  end

  create_table "character_achievements", force: :cascade do |t|
    t.bigint "character_id", null: false
    t.bigint "achievement_id", null: false
    t.boolean "completed", default: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["achievement_id"], name: "index_character_achievements_on_achievement_id"
    t.index ["character_id", "achievement_id"], name: "index_char_achievements_on_char_and_achievement", unique: true
    t.index ["character_id"], name: "index_character_achievements_on_character_id"
  end

  create_table "characters", force: :cascade do |t|
    t.string "pseudo"
    t.bigint "user_id", null: false
    t.bigint "wow_class_id"
    t.bigint "specialization_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "temporary", default: false
    t.string "realm"
    t.string "region", default: "eu"
    t.index ["specialization_id"], name: "index_characters_on_specialization_id"
    t.index ["user_id"], name: "index_characters_on_user_id"
    t.index ["wow_class_id"], name: "index_characters_on_wow_class_id"
  end

  create_table "consumable_selections", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "consumable_id", null: false
    t.integer "quantity"
    t.date "week"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["consumable_id"], name: "index_consumable_selections_on_consumable_id"
    t.index ["user_id"], name: "index_consumable_selections_on_user_id"
  end

  create_table "consumables", force: :cascade do |t|
    t.string "name"
    t.string "category"
    t.string "expansion"
    t.string "icon_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "blizzard_id"
  end

  create_table "event_participations", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "character_id", null: false
    t.bigint "specialization_id"
    t.string "status", default: "confirmed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["character_id"], name: "index_event_participations_on_character_id"
    t.index ["event_id", "character_id"], name: "index_event_participations_on_event_id_and_character_id", unique: true
    t.index ["event_id"], name: "index_event_participations_on_event_id"
    t.index ["specialization_id"], name: "index_event_participations_on_specialization_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.datetime "start_time", null: false
    t.datetime "end_time"
    t.string "event_type", default: "raid"
    t.integer "max_participants"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_events_on_user_id"
  end

  create_table "expansions", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.string "slug", null: false
    t.integer "order_index", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_expansions_on_code", unique: true
  end

  create_table "farm_contributions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "ingredient_id", null: false
    t.integer "quantity"
    t.date "week"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ingredient_id"], name: "index_farm_contributions_on_ingredient_id"
    t.index ["user_id"], name: "index_farm_contributions_on_user_id"
  end

  create_table "farmer_assignments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "ingredient_id", null: false
    t.date "week"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ingredient_id"], name: "index_farmer_assignments_on_ingredient_id"
    t.index ["user_id"], name: "index_farmer_assignments_on_user_id"
  end

  create_table "ingredients", force: :cascade do |t|
    t.string "name"
    t.string "category"
    t.string "icon_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "blizzard_id"
    t.integer "objective_quantity", default: 500
  end

  create_table "recipes", force: :cascade do |t|
    t.bigint "consumable_id", null: false
    t.bigint "ingredient_id", null: false
    t.integer "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["consumable_id"], name: "index_recipes_on_consumable_id"
    t.index ["ingredient_id"], name: "index_recipes_on_ingredient_id"
  end

  create_table "specializations", force: :cascade do |t|
    t.string "name"
    t.string "role"
    t.bigint "wow_class_id", null: false
    t.string "icon"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["wow_class_id"], name: "index_specializations_on_wow_class_id"
  end

  create_table "user_achievement_syncs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "character_name"
    t.string "realm"
    t.string "region", default: "eu"
    t.text "synced_achievement_ids"
    t.datetime "synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "character_name", "realm"], name: "index_user_achievement_syncs_on_user_and_character", unique: true
    t.index ["user_id"], name: "index_user_achievement_syncs_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "pseudo"
    t.string "nickname"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "wow_classes", force: :cascade do |t|
    t.string "name"
    t.string "icon"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "achievements", "expansions"
  add_foreign_key "character_achievements", "achievements"
  add_foreign_key "character_achievements", "characters"
  add_foreign_key "characters", "specializations"
  add_foreign_key "characters", "users"
  add_foreign_key "characters", "wow_classes"
  add_foreign_key "consumable_selections", "consumables"
  add_foreign_key "consumable_selections", "users"
  add_foreign_key "event_participations", "characters"
  add_foreign_key "event_participations", "events"
  add_foreign_key "event_participations", "specializations"
  add_foreign_key "events", "users"
  add_foreign_key "farm_contributions", "ingredients"
  add_foreign_key "farm_contributions", "users"
  add_foreign_key "farmer_assignments", "ingredients"
  add_foreign_key "farmer_assignments", "users"
  add_foreign_key "recipes", "consumables"
  add_foreign_key "recipes", "ingredients"
  add_foreign_key "specializations", "wow_classes"
  add_foreign_key "user_achievement_syncs", "users"
end
