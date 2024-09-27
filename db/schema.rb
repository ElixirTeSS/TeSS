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

ActiveRecord::Schema[7.0].define(version: 2024_07_18_100022) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "activities", force: :cascade do |t|
    t.integer "trackable_id"
    t.string "trackable_type"
    t.integer "owner_id"
    t.string "owner_type"
    t.string "key"
    t.text "parameters"
    t.integer "recipient_id"
    t.string "recipient_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["key"], name: "index_activities_on_key"
    t.index ["owner_id", "owner_type"], name: "index_activities_on_owner_id_and_owner_type"
    t.index ["recipient_id", "recipient_type"], name: "index_activities_on_recipient_id_and_recipient_type"
    t.index ["trackable_id", "trackable_type"], name: "index_activities_on_trackable_id_and_trackable_type"
  end

  create_table "ahoy_events", force: :cascade do |t|
    t.bigint "visit_id"
    t.bigint "user_id"
    t.string "name"
    t.jsonb "properties"
    t.datetime "time"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["properties"], name: "index_ahoy_events_on_properties", opclass: :jsonb_path_ops, using: :gin
    t.index ["user_id"], name: "index_ahoy_events_on_user_id"
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_visits", force: :cascade do |t|
    t.string "visit_token"
    t.string "visitor_token"
    t.bigint "user_id"
    t.string "ip"
    t.text "user_agent"
    t.text "referrer"
    t.string "referring_domain"
    t.text "landing_page"
    t.string "browser"
    t.string "os"
    t.string "device_type"
    t.string "country"
    t.string "region"
    t.string "city"
    t.float "latitude"
    t.float "longitude"
    t.string "utm_source"
    t.string "utm_medium"
    t.string "utm_term"
    t.string "utm_content"
    t.string "utm_campaign"
    t.string "app_version"
    t.string "os_version"
    t.string "platform"
    t.datetime "started_at"
    t.index ["user_id"], name: "index_ahoy_visits_on_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
  end

  create_table "autocomplete_suggestions", force: :cascade do |t|
    t.string "field"
    t.string "value"
    t.index ["field", "value"], name: "index_autocomplete_suggestions_on_field_and_value", unique: true
  end

  create_table "bans", force: :cascade do |t|
    t.integer "user_id"
    t.integer "banner_id"
    t.boolean "shadow"
    t.text "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["banner_id"], name: "index_bans_on_banner_id"
    t.index ["user_id"], name: "index_bans_on_user_id"
  end

  create_table "collaborations", force: :cascade do |t|
    t.integer "user_id"
    t.integer "resource_id"
    t.string "resource_type"
    t.index ["resource_type", "resource_id"], name: "index_collaborations_on_resource_type_and_resource_id"
    t.index ["user_id"], name: "index_collaborations_on_user_id"
  end

  create_table "collection_items", force: :cascade do |t|
    t.bigint "collection_id"
    t.string "resource_type"
    t.bigint "resource_id"
    t.text "comment"
    t.integer "order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id"], name: "index_collection_items_on_collection_id"
    t.index ["resource_type", "resource_id"], name: "index_collection_items_on_resource"
  end

  create_table "collections", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.text "image_url"
    t.boolean "public", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "slug"
    t.string "keywords", default: [], array: true
    t.string "image_file_name"
    t.string "image_content_type"
    t.bigint "image_file_size"
    t.datetime "image_updated_at"
    t.index ["slug"], name: "index_collections_on_slug", unique: true
    t.index ["user_id"], name: "index_collections_on_user_id"
  end

  create_table "content_providers", force: :cascade do |t|
    t.text "title"
    t.text "url"
    t.text "image_url"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.string "keywords", default: [], array: true
    t.integer "user_id"
    t.integer "node_id"
    t.string "content_provider_type", default: "Organisation"
    t.string "image_file_name"
    t.string "image_content_type"
    t.bigint "image_file_size"
    t.datetime "image_updated_at"
    t.string "contact"
    t.string "event_curation_email"
    t.index ["node_id"], name: "index_content_providers_on_node_id"
    t.index ["slug"], name: "index_content_providers_on_slug", unique: true
    t.index ["user_id"], name: "index_content_providers_on_user_id"
  end

  create_table "content_providers_users", id: false, force: :cascade do |t|
    t.bigint "content_provider_id"
    t.bigint "user_id"
    t.index ["content_provider_id", "user_id"], name: "provider_user_unique", unique: true
    t.index ["content_provider_id"], name: "index_content_providers_users_on_content_provider_id"
    t.index ["user_id"], name: "index_content_providers_users_on_user_id"
  end

  create_table "edit_suggestions", force: :cascade do |t|
    t.text "name"
    t.text "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "suggestible_id"
    t.string "suggestible_type"
    t.json "data_fields", default: {}
    t.index ["suggestible_id", "suggestible_type"], name: "index_edit_suggestions_on_suggestible_id_and_suggestible_type"
  end

  create_table "event_materials", force: :cascade do |t|
    t.integer "event_id"
    t.integer "material_id"
    t.index ["event_id"], name: "index_event_materials_on_event_id"
    t.index ["material_id"], name: "index_event_materials_on_material_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "external_id"
    t.string "title"
    t.string "subtitle"
    t.string "url"
    t.string "organizer"
    t.text "description"
    t.datetime "start"
    t.datetime "end"
    t.string "sponsors", default: [], array: true
    t.text "venue"
    t.string "city"
    t.string "county"
    t.string "country"
    t.string "postcode"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "source", default: "tess"
    t.string "slug"
    t.integer "content_provider_id"
    t.integer "user_id"
    t.integer "presence", default: 0
    t.decimal "cost_value"
    t.date "last_scraped"
    t.boolean "scraper_record", default: false
    t.string "keywords", default: [], array: true
    t.string "event_types", default: [], array: true
    t.string "target_audience", default: [], array: true
    t.integer "capacity"
    t.string "eligibility", default: [], array: true
    t.text "contact"
    t.string "host_institutions", default: [], array: true
    t.string "timezone"
    t.string "funding"
    t.integer "attendee_count"
    t.integer "applicant_count"
    t.integer "trainer_count"
    t.string "feedback"
    t.text "notes"
    t.integer "nominatim_count", default: 0
    t.string "duration"
    t.text "recognition"
    t.text "learning_objectives"
    t.text "prerequisites"
    t.text "tech_requirements"
    t.string "cost_basis"
    t.string "cost_currency"
    t.string "fields", default: [], array: true
    t.string "open_science", default: [], array: true
    t.boolean "visible", default: true
    t.string "language"
    t.index ["presence"], name: "index_events_on_presence"
    t.index ["slug"], name: "index_events_on_slug", unique: true
    t.index ["user_id"], name: "index_events_on_user_id"
  end

  create_table "external_resources", force: :cascade do |t|
    t.integer "source_id"
    t.text "url"
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "source_type"
    t.index ["source_id", "source_type"], name: "index_external_resources_on_source_id_and_source_type"
  end

  create_table "field_locks", force: :cascade do |t|
    t.integer "resource_id"
    t.string "resource_type"
    t.string "field"
    t.index ["resource_type", "resource_id"], name: "index_field_locks_on_resource_type_and_resource_id"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "learning_path_topic_items", force: :cascade do |t|
    t.bigint "topic_id"
    t.string "resource_type"
    t.bigint "resource_id"
    t.text "comment"
    t.integer "order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["resource_type", "resource_id"], name: "index_learning_path_topic_items_on_resource"
    t.index ["topic_id"], name: "index_learning_path_topic_items_on_topic_id"
  end

  create_table "learning_path_topic_links", force: :cascade do |t|
    t.bigint "learning_path_id"
    t.bigint "topic_id"
    t.integer "order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["learning_path_id"], name: "index_learning_path_topic_links_on_learning_path_id"
    t.index ["topic_id"], name: "index_learning_path_topic_links_on_topic_id"
  end

  create_table "learning_path_topics", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.integer "user_id"
    t.string "keywords", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "difficulty_level", default: "notspecified"
  end

  create_table "learning_paths", force: :cascade do |t|
    t.text "title"
    t.text "description"
    t.string "doi"
    t.string "target_audience", default: [], array: true
    t.string "authors", default: [], array: true
    t.string "contributors", default: [], array: true
    t.string "licence", default: "notspecified"
    t.string "difficulty_level", default: "notspecified"
    t.string "slug"
    t.bigint "user_id"
    t.bigint "content_provider_id"
    t.string "keywords", default: [], array: true
    t.text "prerequisites"
    t.text "learning_objectives"
    t.string "status"
    t.string "learning_path_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "public", default: true
    t.index ["content_provider_id"], name: "index_learning_paths_on_content_provider_id"
    t.index ["slug"], name: "index_learning_paths_on_slug", unique: true
    t.index ["user_id"], name: "index_learning_paths_on_user_id"
  end

  create_table "link_monitors", force: :cascade do |t|
    t.string "url"
    t.integer "code"
    t.datetime "failed_at"
    t.datetime "last_failed_at"
    t.integer "fail_count"
    t.integer "lcheck_id"
    t.string "lcheck_type"
    t.index ["lcheck_type", "lcheck_id"], name: "index_link_monitors_on_lcheck_type_and_lcheck_id"
  end

  create_table "llm_interactions", force: :cascade do |t|
    t.bigint "event_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "scrape_or_process"
    t.string "model"
    t.string "prompt"
    t.string "input"
    t.string "output"
    t.boolean "needs_processing", default: false
    t.index ["event_id"], name: "index_llm_interactions_on_event_id"
  end

  create_table "materials", force: :cascade do |t|
    t.text "title"
    t.string "url"
    t.string "doi"
    t.date "remote_updated_date"
    t.date "remote_created_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.string "target_audience", default: [], array: true
    t.string "authors", default: [], array: true
    t.string "contributors", default: [], array: true
    t.string "licence", default: "notspecified"
    t.string "difficulty_level", default: "notspecified"
    t.integer "content_provider_id"
    t.string "slug"
    t.integer "user_id"
    t.date "last_scraped"
    t.boolean "scraper_record", default: false
    t.string "resource_type", default: [], array: true
    t.string "keywords", default: [], array: true
    t.string "other_types"
    t.date "date_created"
    t.date "date_modified"
    t.date "date_published"
    t.text "prerequisites"
    t.string "version"
    t.string "status"
    t.text "syllabus"
    t.string "subsets", default: [], array: true
    t.text "contact"
    t.text "learning_objectives"
    t.string "fields", default: [], array: true
    t.index ["content_provider_id"], name: "index_materials_on_content_provider_id"
    t.index ["slug"], name: "index_materials_on_slug", unique: true
    t.index ["user_id"], name: "index_materials_on_user_id"
  end

  create_table "node_links", force: :cascade do |t|
    t.integer "node_id"
    t.integer "resource_id"
    t.string "resource_type"
    t.index ["node_id"], name: "index_node_links_on_node_id"
    t.index ["resource_type", "resource_id"], name: "index_node_links_on_resource_type_and_resource_id"
  end

  create_table "nodes", force: :cascade do |t|
    t.string "name"
    t.string "member_status"
    t.string "country_code"
    t.string "home_page"
    t.string "twitter"
    t.string "carousel_images", array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.integer "user_id"
    t.text "image_url"
    t.text "description"
    t.index ["slug"], name: "index_nodes_on_slug", unique: true
    t.index ["user_id"], name: "index_nodes_on_user_id"
  end

  create_table "ontology_term_links", force: :cascade do |t|
    t.integer "resource_id"
    t.string "resource_type"
    t.string "term_uri"
    t.string "field"
    t.index ["field"], name: "index_ontology_term_links_on_field"
    t.index ["resource_type", "resource_id"], name: "index_ontology_term_links_on_resource_type_and_resource_id"
    t.index ["term_uri"], name: "index_ontology_term_links_on_term_uri"
  end

  create_table "profiles", force: :cascade do |t|
    t.text "firstname"
    t.text "surname"
    t.text "image_url"
    t.text "email"
    t.text "website"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "slug"
    t.boolean "public", default: false
    t.text "description"
    t.text "location"
    t.string "orcid"
    t.string "experience"
    t.string "expertise_academic", default: [], array: true
    t.string "expertise_technical", default: [], array: true
    t.string "interest", default: [], array: true
    t.string "activity", default: [], array: true
    t.string "language", default: [], array: true
    t.string "social_media", default: [], array: true
    t.string "type", default: "Profile"
    t.string "fields", default: [], array: true
    t.index ["slug"], name: "index_profiles_on_slug", unique: true
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
  end

  create_table "sources", force: :cascade do |t|
    t.bigint "content_provider_id"
    t.bigint "user_id"
    t.datetime "created_at"
    t.datetime "finished_at"
    t.string "url"
    t.string "method"
    t.integer "records_read"
    t.integer "records_written"
    t.integer "resources_added"
    t.integer "resources_updated"
    t.integer "resources_rejected"
    t.text "log"
    t.boolean "enabled"
    t.string "token"
    t.integer "approval_status"
    t.datetime "updated_at"
    t.index ["content_provider_id"], name: "index_sources_on_content_provider_id"
    t.index ["user_id"], name: "index_sources_on_user_id"
  end

  create_table "staff_members", force: :cascade do |t|
    t.string "name"
    t.string "role"
    t.string "email"
    t.text "image_url"
    t.integer "node_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "image_file_name"
    t.string "image_content_type"
    t.bigint "image_file_size"
    t.datetime "image_updated_at"
    t.index ["node_id"], name: "index_staff_members_on_node_id"
  end

  create_table "stars", force: :cascade do |t|
    t.integer "user_id"
    t.integer "resource_id"
    t.string "resource_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["resource_type", "resource_id"], name: "index_stars_on_resource_type_and_resource_id"
    t.index ["user_id"], name: "index_stars_on_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer "user_id"
    t.datetime "last_sent_at"
    t.text "query"
    t.json "facets"
    t.integer "frequency"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "subscribable_type"
    t.datetime "last_checked_at"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username"
    t.integer "role_id"
    t.string "authentication_token"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "slug"
    t.string "provider"
    t.string "uid"
    t.string "identity_url"
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.bigint "invited_by_id"
    t.integer "invitations_count", default: 0
    t.text "image_url"
    t.string "image_file_name"
    t.string "image_content_type"
    t.bigint "image_file_size"
    t.datetime "image_updated_at"
    t.index ["authentication_token"], name: "index_users_on_authentication_token"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["identity_url"], name: "index_users_on_identity_url", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role_id"], name: "index_users_on_role_id"
    t.index ["slug"], name: "index_users_on_slug", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "widget_logs", force: :cascade do |t|
    t.string "widget_name"
    t.string "action"
    t.integer "resource_id"
    t.string "resource_type"
    t.text "data"
    t.json "params"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["resource_type", "resource_id"], name: "index_widget_logs_on_resource_type_and_resource_id"
  end

  create_table "workflows", force: :cascade do |t|
    t.string "title"
    t.string "description"
    t.integer "user_id"
    t.json "workflow_content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.string "target_audience", default: [], array: true
    t.string "keywords", default: [], array: true
    t.string "authors", default: [], array: true
    t.string "contributors", default: [], array: true
    t.string "licence", default: "notspecified"
    t.string "difficulty_level", default: "notspecified"
    t.string "doi"
    t.date "remote_created_date"
    t.date "remote_updated_date"
    t.boolean "hide_child_nodes", default: false
    t.boolean "public", default: true
    t.index ["slug"], name: "index_workflows_on_slug", unique: true
    t.index ["user_id"], name: "index_workflows_on_user_id"
  end

  add_foreign_key "bans", "users"
  add_foreign_key "bans", "users", column: "banner_id"
  add_foreign_key "collaborations", "users"
  add_foreign_key "collections", "users"
  add_foreign_key "content_providers", "nodes"
  add_foreign_key "content_providers", "users"
  add_foreign_key "event_materials", "events"
  add_foreign_key "event_materials", "materials"
  add_foreign_key "events", "users"
  add_foreign_key "learning_path_topic_links", "learning_paths"
  add_foreign_key "learning_paths", "content_providers"
  add_foreign_key "learning_paths", "users"
  add_foreign_key "llm_interactions", "events"
  add_foreign_key "materials", "content_providers"
  add_foreign_key "materials", "users"
  add_foreign_key "node_links", "nodes"
  add_foreign_key "nodes", "users"
  add_foreign_key "sources", "content_providers"
  add_foreign_key "sources", "users"
  add_foreign_key "staff_members", "nodes"
  add_foreign_key "stars", "users"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "users", "roles"
  add_foreign_key "workflows", "users"
end
