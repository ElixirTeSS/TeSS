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

ActiveRecord::Schema[8.1].define(version: 2026_07_29_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "activities", force: :cascade do |t|
    t.datetime "created_at"
    t.string "key"
    t.integer "owner_id"
    t.string "owner_type"
    t.text "parameters"
    t.integer "recipient_id"
    t.string "recipient_type"
    t.integer "trackable_id"
    t.string "trackable_type"
    t.datetime "updated_at"
    t.index ["key"], name: "index_activities_on_key"
    t.index ["owner_id", "owner_type"], name: "index_activities_on_owner_id_and_owner_type"
    t.index ["recipient_id", "recipient_type"], name: "index_activities_on_recipient_id_and_recipient_type"
    t.index ["trackable_id", "trackable_type"], name: "index_activities_on_trackable_id_and_trackable_type"
  end

  create_table "ahoy_events", force: :cascade do |t|
    t.string "name"
    t.jsonb "properties"
    t.datetime "time"
    t.bigint "user_id"
    t.bigint "visit_id"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["properties"], name: "index_ahoy_events_on_properties", opclass: :jsonb_path_ops, using: :gin
    t.index ["user_id"], name: "index_ahoy_events_on_user_id"
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_visits", force: :cascade do |t|
    t.string "app_version"
    t.string "browser"
    t.string "city"
    t.string "country"
    t.string "device_type"
    t.string "ip"
    t.text "landing_page"
    t.float "latitude"
    t.float "longitude"
    t.string "os"
    t.string "os_version"
    t.string "platform"
    t.text "referrer"
    t.string "referring_domain"
    t.string "region"
    t.datetime "started_at"
    t.text "user_agent"
    t.bigint "user_id"
    t.string "utm_campaign"
    t.string "utm_content"
    t.string "utm_medium"
    t.string "utm_source"
    t.string "utm_term"
    t.string "visit_token"
    t.string "visitor_token"
    t.index ["user_id"], name: "index_ahoy_visits_on_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
  end

  create_table "autocomplete_suggestions", force: :cascade do |t|
    t.string "field"
    t.string "value"
    t.index ["field", "value"], name: "index_autocomplete_suggestions_on_field_and_value", unique: true
  end

  create_table "bans", force: :cascade do |t|
    t.integer "banner_id"
    t.datetime "created_at", null: false
    t.text "reason"
    t.boolean "shadow"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["banner_id"], name: "index_bans_on_banner_id"
    t.index ["user_id"], name: "index_bans_on_user_id"
  end

  create_table "collaborations", force: :cascade do |t|
    t.integer "resource_id"
    t.string "resource_type"
    t.integer "user_id"
    t.index ["resource_type", "resource_id"], name: "index_collaborations_on_resource_type_and_resource_id"
    t.index ["user_id"], name: "index_collaborations_on_user_id"
  end

  create_table "collection_items", force: :cascade do |t|
    t.bigint "collection_id"
    t.text "comment"
    t.datetime "created_at", null: false
    t.integer "order"
    t.bigint "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.index ["collection_id"], name: "index_collection_items_on_collection_id"
    t.index ["resource_type", "resource_id"], name: "index_collection_items_on_resource"
  end

  create_table "collections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "image_content_type"
    t.string "image_file_name"
    t.bigint "image_file_size"
    t.datetime "image_updated_at"
    t.text "image_url"
    t.string "keywords", default: [], array: true
    t.boolean "public", default: true
    t.string "slug"
    t.bigint "space_id"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["slug"], name: "index_collections_on_slug", unique: true
    t.index ["space_id"], name: "index_collections_on_space_id"
    t.index ["user_id"], name: "index_collections_on_user_id"
  end

  create_table "content_providers", force: :cascade do |t|
    t.string "contact"
    t.string "content_curation_email"
    t.string "content_provider_type", default: "Organisation"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "image_content_type"
    t.string "image_file_name"
    t.bigint "image_file_size"
    t.datetime "image_updated_at"
    t.text "image_url"
    t.string "keywords", default: [], array: true
    t.integer "node_id"
    t.string "slug"
    t.text "title"
    t.datetime "updated_at", null: false
    t.text "url"
    t.integer "user_id"
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
    t.datetime "created_at", null: false
    t.json "data_fields", default: {}
    t.text "name"
    t.integer "suggestible_id"
    t.string "suggestible_type"
    t.text "text"
    t.datetime "updated_at", null: false
    t.index ["suggestible_id", "suggestible_type"], name: "index_edit_suggestions_on_suggestible_id_and_suggestible_type"
  end

  create_table "event_materials", force: :cascade do |t|
    t.integer "event_id"
    t.integer "material_id"
    t.index ["event_id"], name: "index_event_materials_on_event_id"
    t.index ["material_id"], name: "index_event_materials_on_material_id"
  end

  create_table "events", force: :cascade do |t|
    t.integer "applicant_count"
    t.integer "attendee_count"
    t.integer "capacity"
    t.string "city"
    t.text "contact"
    t.integer "content_provider_id"
    t.string "cost_basis"
    t.string "cost_currency"
    t.decimal "cost_value"
    t.string "country"
    t.string "county"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "duration"
    t.string "eligibility", default: [], array: true
    t.datetime "end"
    t.string "event_types", default: [], array: true
    t.string "external_id"
    t.string "feedback"
    t.string "fields", default: [], array: true
    t.string "funding"
    t.string "host_institutions", default: [], array: true
    t.string "keywords", default: [], array: true
    t.string "language"
    t.date "last_scraped"
    t.bigint "last_scraped_by_id"
    t.decimal "latitude", precision: 10, scale: 6
    t.text "learning_objectives"
    t.decimal "longitude", precision: 10, scale: 6
    t.integer "nominatim_count", default: 0
    t.text "notes"
    t.string "open_science", default: [], array: true
    t.string "organizer"
    t.string "origin_uri"
    t.string "postcode"
    t.text "prerequisites"
    t.integer "presence", default: 0
    t.text "recognition"
    t.boolean "scraper_record", default: false
    t.string "slug"
    t.text "source", default: "tess"
    t.bigint "space_id"
    t.string "sponsors", default: [], array: true
    t.datetime "start"
    t.string "subtitle"
    t.string "target_audience", default: [], array: true
    t.text "tech_requirements"
    t.string "timezone"
    t.string "title"
    t.integer "trainer_count"
    t.datetime "updated_at", null: false
    t.string "url"
    t.integer "user_id"
    t.text "venue"
    t.boolean "visible", default: true
    t.index ["last_scraped_by_id"], name: "index_events_on_last_scraped_by_id"
    t.index ["presence"], name: "index_events_on_presence"
    t.index ["slug"], name: "index_events_on_slug", unique: true
    t.index ["space_id"], name: "index_events_on_space_id"
    t.index ["user_id"], name: "index_events_on_user_id"
  end

  create_table "external_resources", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "source_id"
    t.string "source_type"
    t.string "title"
    t.datetime "updated_at", null: false
    t.text "url"
    t.index ["source_id", "source_type"], name: "index_external_resources_on_source_id_and_source_type"
  end

  create_table "field_locks", force: :cascade do |t|
    t.string "field"
    t.integer "resource_id"
    t.string "resource_type"
    t.index ["resource_type", "resource_id"], name: "index_field_locks_on_resource_type_and_resource_id"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.datetime "created_at"
    t.string "scope"
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "learning_path_topic_items", force: :cascade do |t|
    t.text "comment"
    t.datetime "created_at", null: false
    t.integer "order"
    t.bigint "resource_id"
    t.string "resource_type"
    t.bigint "topic_id"
    t.datetime "updated_at", null: false
    t.index ["resource_type", "resource_id"], name: "index_learning_path_topic_items_on_resource"
    t.index ["topic_id"], name: "index_learning_path_topic_items_on_topic_id"
  end

  create_table "learning_path_topic_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "learning_path_id"
    t.integer "order"
    t.bigint "topic_id"
    t.datetime "updated_at", null: false
    t.index ["learning_path_id"], name: "index_learning_path_topic_links_on_learning_path_id"
    t.index ["topic_id"], name: "index_learning_path_topic_links_on_topic_id"
  end

  create_table "learning_path_topics", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "difficulty_level", default: "notspecified"
    t.string "keywords", default: [], array: true
    t.bigint "space_id"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["space_id"], name: "index_learning_path_topics_on_space_id"
  end

  create_table "learning_paths", force: :cascade do |t|
    t.bigint "content_provider_id"
    t.datetime "created_at", null: false
    t.string "deprecated_authors", default: [], array: true
    t.string "deprecated_contributors", default: [], array: true
    t.text "description"
    t.string "difficulty_level", default: "notspecified"
    t.string "doi"
    t.string "keywords", default: [], array: true
    t.text "learning_objectives"
    t.string "learning_path_type"
    t.string "licence", default: "notspecified"
    t.text "prerequisites"
    t.boolean "public", default: true
    t.string "slug"
    t.bigint "space_id"
    t.string "status"
    t.string "target_audience", default: [], array: true
    t.text "title"
    t.boolean "unordered", default: false, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["content_provider_id"], name: "index_learning_paths_on_content_provider_id"
    t.index ["slug"], name: "index_learning_paths_on_slug", unique: true
    t.index ["space_id"], name: "index_learning_paths_on_space_id"
    t.index ["user_id"], name: "index_learning_paths_on_user_id"
  end

  create_table "link_monitors", force: :cascade do |t|
    t.integer "code"
    t.integer "fail_count"
    t.datetime "failed_at"
    t.datetime "last_failed_at"
    t.integer "lcheck_id"
    t.string "lcheck_type"
    t.string "url"
    t.index ["lcheck_type", "lcheck_id"], name: "index_link_monitors_on_lcheck_type_and_lcheck_id"
  end

  create_table "llm_interactions", force: :cascade do |t|
    t.datetime "created_at"
    t.bigint "event_id"
    t.string "input"
    t.string "model"
    t.boolean "needs_processing", default: false
    t.string "output"
    t.string "prompt"
    t.string "scrape_or_process"
    t.datetime "updated_at"
    t.index ["event_id"], name: "index_llm_interactions_on_event_id"
  end

  create_table "materials", force: :cascade do |t|
    t.text "contact"
    t.integer "content_provider_id"
    t.datetime "created_at", null: false
    t.date "date_created"
    t.date "date_modified"
    t.date "date_published"
    t.string "deprecated_authors", default: [], array: true
    t.string "deprecated_contributors", default: [], array: true
    t.text "description"
    t.string "difficulty_level", default: "notspecified"
    t.string "doi"
    t.string "fields", default: [], array: true
    t.string "keywords", default: [], array: true
    t.date "last_scraped"
    t.bigint "last_scraped_by_id"
    t.text "learning_objectives"
    t.string "licence", default: "notspecified"
    t.string "origin_uri"
    t.string "other_types"
    t.text "prerequisites"
    t.date "remote_created_date"
    t.date "remote_updated_date"
    t.string "resource_type", default: [], array: true
    t.boolean "scraper_record", default: false
    t.string "slug"
    t.bigint "space_id"
    t.string "status"
    t.string "subsets", default: [], array: true
    t.text "syllabus"
    t.string "target_audience", default: [], array: true
    t.text "title"
    t.datetime "updated_at", null: false
    t.string "url"
    t.integer "user_id"
    t.string "version"
    t.boolean "visible", default: true
    t.index ["content_provider_id"], name: "index_materials_on_content_provider_id"
    t.index ["last_scraped_by_id"], name: "index_materials_on_last_scraped_by_id"
    t.index ["slug"], name: "index_materials_on_slug", unique: true
    t.index ["space_id"], name: "index_materials_on_space_id"
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
    t.string "carousel_images", array: true
    t.string "country_code"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "home_page"
    t.text "image_url"
    t.string "member_status"
    t.string "name"
    t.string "slug"
    t.string "twitter"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["slug"], name: "index_nodes_on_slug", unique: true
    t.index ["user_id"], name: "index_nodes_on_user_id"
  end

  create_table "ontology_term_links", force: :cascade do |t|
    t.string "field"
    t.integer "resource_id"
    t.string "resource_type"
    t.string "term_uri"
    t.index ["field"], name: "index_ontology_term_links_on_field"
    t.index ["resource_type", "resource_id"], name: "index_ontology_term_links_on_resource_type_and_resource_id"
    t.index ["term_uri"], name: "index_ontology_term_links_on_term_uri"
  end

  create_table "people", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.string "orcid"
    t.bigint "profile_id"
    t.bigint "resource_id", null: false
    t.string "resource_type", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_people_on_name"
    t.index ["orcid"], name: "index_people_on_orcid"
    t.index ["profile_id"], name: "index_people_on_profile_id"
    t.index ["resource_type", "resource_id", "role"], name: "index_people_on_resource_type_and_resource_id_and_role"
    t.index ["resource_type", "resource_id"], name: "index_people_on_resource"
  end

  create_table "profiles", force: :cascade do |t|
    t.string "activity", default: [], array: true
    t.datetime "created_at", null: false
    t.text "description"
    t.text "email"
    t.string "experience"
    t.string "expertise_academic", default: [], array: true
    t.string "expertise_technical", default: [], array: true
    t.string "fields", default: [], array: true
    t.text "firstname"
    t.text "image_url"
    t.string "interest", default: [], array: true
    t.string "language", default: [], array: true
    t.text "location"
    t.string "orcid"
    t.boolean "orcid_authenticated", default: false
    t.boolean "public", default: false
    t.string "slug"
    t.string "social_media", default: [], array: true
    t.text "surname"
    t.string "type", default: "Profile"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.text "website"
    t.index ["orcid"], name: "index_profiles_on_orcid"
    t.index ["slug"], name: "index_profiles_on_slug", unique: true
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "source_filters", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "mode"
    t.string "property"
    t.bigint "source_id", null: false
    t.datetime "updated_at", null: false
    t.string "value"
    t.index ["source_id"], name: "index_source_filters_on_source_id"
  end

  create_table "sources", force: :cascade do |t|
    t.integer "approval_status"
    t.bigint "content_provider_id"
    t.datetime "created_at"
    t.string "default_language"
    t.boolean "enabled"
    t.datetime "finished_at"
    t.text "log"
    t.string "method"
    t.integer "records_read"
    t.integer "records_written"
    t.integer "resources_added"
    t.integer "resources_rejected"
    t.integer "resources_updated"
    t.bigint "space_id"
    t.string "token"
    t.datetime "updated_at"
    t.string "url"
    t.bigint "user_id"
    t.index ["content_provider_id"], name: "index_sources_on_content_provider_id"
    t.index ["space_id"], name: "index_sources_on_space_id"
    t.index ["user_id"], name: "index_sources_on_user_id"
  end

  create_table "space_roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key"
    t.bigint "space_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["space_id"], name: "index_space_roles_on_space_id"
    t.index ["user_id"], name: "index_space_roles_on_user_id"
  end

  create_table "spaces", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "disabled_features", default: [], array: true
    t.string "host"
    t.string "image_content_type"
    t.string "image_file_name"
    t.bigint "image_file_size"
    t.datetime "image_updated_at"
    t.text "image_url"
    t.string "theme"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["host"], name: "index_spaces_on_host", unique: true
    t.index ["user_id"], name: "index_spaces_on_user_id"
  end

  create_table "staff_members", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "image_content_type"
    t.string "image_file_name"
    t.bigint "image_file_size"
    t.datetime "image_updated_at"
    t.text "image_url"
    t.string "name"
    t.integer "node_id"
    t.string "role"
    t.datetime "updated_at", null: false
    t.index ["node_id"], name: "index_staff_members_on_node_id"
  end

  create_table "stars", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["resource_type", "resource_id"], name: "index_stars_on_resource_type_and_resource_id"
    t.index ["user_id"], name: "index_stars_on_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "facets"
    t.integer "frequency"
    t.datetime "last_checked_at"
    t.datetime "last_sent_at"
    t.text "query"
    t.bigint "space_id"
    t.string "subscribable_type"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["space_id"], name: "index_subscriptions_on_space_id"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "authentication_token"
    t.boolean "check_broken_scrapers", default: false
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.inet "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "identity_url"
    t.string "image_content_type"
    t.string "image_file_name"
    t.bigint "image_file_size"
    t.datetime "image_updated_at"
    t.text "image_url"
    t.datetime "invitation_accepted_at"
    t.datetime "invitation_created_at"
    t.integer "invitation_limit"
    t.datetime "invitation_sent_at"
    t.string "invitation_token"
    t.integer "invitations_count", default: 0
    t.bigint "invited_by_id"
    t.string "invited_by_type"
    t.datetime "last_sign_in_at"
    t.inet "last_sign_in_ip"
    t.datetime "locked_at"
    t.string "provider"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role_id"
    t.integer "sign_in_count", default: 0, null: false
    t.string "slug"
    t.string "uid"
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.string "username"
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
    t.string "action"
    t.datetime "created_at", null: false
    t.text "data"
    t.json "params"
    t.text "referrer"
    t.integer "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.string "widget_name"
    t.index ["resource_type", "resource_id"], name: "index_widget_logs_on_resource_type_and_resource_id"
  end

  create_table "workflows", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "deprecated_authors", default: [], array: true
    t.string "deprecated_contributors", default: [], array: true
    t.string "description"
    t.string "difficulty_level", default: "notspecified"
    t.string "doi"
    t.boolean "hide_child_nodes", default: false
    t.string "keywords", default: [], array: true
    t.string "licence", default: "notspecified"
    t.boolean "public", default: true
    t.date "remote_created_date"
    t.date "remote_updated_date"
    t.string "slug"
    t.bigint "space_id"
    t.string "target_audience", default: [], array: true
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.json "workflow_content"
    t.index ["slug"], name: "index_workflows_on_slug", unique: true
    t.index ["space_id"], name: "index_workflows_on_space_id"
    t.index ["user_id"], name: "index_workflows_on_user_id"
  end

  add_foreign_key "bans", "users"
  add_foreign_key "bans", "users", column: "banner_id"
  add_foreign_key "collaborations", "users"
  add_foreign_key "collections", "spaces"
  add_foreign_key "collections", "users"
  add_foreign_key "content_providers", "nodes"
  add_foreign_key "content_providers", "users"
  add_foreign_key "event_materials", "events"
  add_foreign_key "event_materials", "materials"
  add_foreign_key "events", "sources", column: "last_scraped_by_id", on_delete: :nullify
  add_foreign_key "events", "spaces"
  add_foreign_key "events", "users"
  add_foreign_key "learning_path_topic_links", "learning_paths"
  add_foreign_key "learning_path_topics", "spaces"
  add_foreign_key "learning_paths", "content_providers"
  add_foreign_key "learning_paths", "spaces"
  add_foreign_key "learning_paths", "users"
  add_foreign_key "llm_interactions", "events"
  add_foreign_key "materials", "content_providers"
  add_foreign_key "materials", "sources", column: "last_scraped_by_id", on_delete: :nullify
  add_foreign_key "materials", "spaces"
  add_foreign_key "materials", "users"
  add_foreign_key "node_links", "nodes"
  add_foreign_key "nodes", "users"
  add_foreign_key "people", "profiles"
  add_foreign_key "source_filters", "sources"
  add_foreign_key "sources", "content_providers"
  add_foreign_key "sources", "spaces"
  add_foreign_key "sources", "users"
  add_foreign_key "space_roles", "spaces"
  add_foreign_key "space_roles", "users"
  add_foreign_key "spaces", "users"
  add_foreign_key "staff_members", "nodes"
  add_foreign_key "stars", "users"
  add_foreign_key "subscriptions", "spaces"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "users", "roles"
  add_foreign_key "workflows", "spaces"
  add_foreign_key "workflows", "users"
end
