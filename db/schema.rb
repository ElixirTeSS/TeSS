# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180604095539) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "activities", force: :cascade do |t|
    t.integer  "trackable_id"
    t.string   "trackable_type"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.string   "key"
    t.text     "parameters"
    t.integer  "recipient_id"
    t.string   "recipient_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "activities", ["key"], name: "index_activities_on_key", using: :btree
  add_index "activities", ["owner_id", "owner_type"], name: "index_activities_on_owner_id_and_owner_type", using: :btree
  add_index "activities", ["recipient_id", "recipient_type"], name: "index_activities_on_recipient_id_and_recipient_type", using: :btree
  add_index "activities", ["trackable_id", "trackable_type"], name: "index_activities_on_trackable_id_and_trackable_type", using: :btree

  create_table "bans", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "banner_id"
    t.boolean  "shadow"
    t.text     "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "bans", ["banner_id"], name: "index_bans_on_banner_id", using: :btree
  add_index "bans", ["user_id"], name: "index_bans_on_user_id", using: :btree

  create_table "collaborations", force: :cascade do |t|
    t.integer "user_id"
    t.integer "resource_id"
    t.string  "resource_type"
  end

  add_index "collaborations", ["resource_type", "resource_id"], name: "index_collaborations_on_resource_type_and_resource_id", using: :btree
  add_index "collaborations", ["user_id"], name: "index_collaborations_on_user_id", using: :btree

  create_table "content_providers", force: :cascade do |t|
    t.text     "title"
    t.text     "url"
    t.text     "image_url"
    t.text     "description"
    t.datetime "created_at",                                     null: false
    t.datetime "updated_at",                                     null: false
    t.string   "slug"
    t.string   "keywords",              default: [],                          array: true
    t.integer  "user_id"
    t.integer  "node_id"
    t.string   "content_provider_type", default: "Organisation"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
  end

  add_index "content_providers", ["node_id"], name: "index_content_providers_on_node_id", using: :btree
  add_index "content_providers", ["slug"], name: "index_content_providers_on_slug", unique: true, using: :btree
  add_index "content_providers", ["user_id"], name: "index_content_providers_on_user_id", using: :btree

  create_table "edit_suggestions", force: :cascade do |t|
    t.text     "name"
    t.text     "text"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.integer  "suggestible_id"
    t.string   "suggestible_type"
    t.json     "data_fields",      default: {}
  end

  add_index "edit_suggestions", ["suggestible_id", "suggestible_type"], name: "index_edit_suggestions_on_suggestible_id_and_suggestible_type", using: :btree

  create_table "event_materials", force: :cascade do |t|
    t.integer "event_id"
    t.integer "material_id"
  end

  add_index "event_materials", ["event_id"], name: "index_event_materials_on_event_id", using: :btree
  add_index "event_materials", ["material_id"], name: "index_event_materials_on_material_id", using: :btree

  create_table "events", force: :cascade do |t|
    t.string   "external_id"
    t.string   "title"
    t.string   "subtitle"
    t.string   "url"
    t.string   "organizer"
    t.text     "description"
    t.datetime "start"
    t.datetime "end"
    t.string   "sponsors",                                     default: [],                  array: true
    t.text     "venue"
    t.string   "city"
    t.string   "county"
    t.string   "country"
    t.string   "postcode"
    t.decimal  "latitude",            precision: 10, scale: 6
    t.decimal  "longitude",           precision: 10, scale: 6
    t.datetime "created_at",                                                    null: false
    t.datetime "updated_at",                                                    null: false
    t.text     "source",                                       default: "tess"
    t.string   "slug"
    t.integer  "content_provider_id"
    t.integer  "user_id"
    t.boolean  "online",                                       default: false
    t.text     "cost"
    t.boolean  "for_profit",                                   default: false
    t.date     "last_scraped"
    t.boolean  "scraper_record",                               default: false
    t.string   "keywords",                                     default: [],                  array: true
    t.string   "event_types",                                  default: [],                  array: true
    t.string   "target_audience",                              default: [],                  array: true
    t.integer  "capacity"
    t.string   "eligibility",                                  default: [],                  array: true
    t.text     "contact"
    t.string   "host_institutions",                            default: [],                  array: true
    t.string   "timezone"
    t.string   "funding"
    t.integer  "attendee_count"
    t.integer  "applicant_count"
    t.integer  "trainer_count"
    t.string   "feedback"
    t.text     "notes"
    t.integer  "nominatim_count",                              default: 0
  end

  add_index "events", ["cost"], name: "index_events_on_cost", using: :btree
  add_index "events", ["for_profit"], name: "index_events_on_for_profit", using: :btree
  add_index "events", ["online"], name: "index_events_on_online", using: :btree
  add_index "events", ["slug"], name: "index_events_on_slug", unique: true, using: :btree
  add_index "events", ["user_id"], name: "index_events_on_user_id", using: :btree

  create_table "external_resources", force: :cascade do |t|
    t.integer  "source_id"
    t.text     "url"
    t.string   "title"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "source_type"
  end

  add_index "external_resources", ["source_id", "source_type"], name: "index_external_resources_on_source_id_and_source_type", using: :btree

  create_table "field_locks", force: :cascade do |t|
    t.integer "resource_id"
    t.string  "resource_type"
    t.string  "field"
  end

  add_index "field_locks", ["resource_type", "resource_id"], name: "index_field_locks_on_resource_type_and_resource_id", using: :btree

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string   "slug",                      null: false
    t.integer  "sluggable_id",              null: false
    t.string   "sluggable_type", limit: 50
    t.string   "scope"
    t.datetime "created_at"
  end

  add_index "friendly_id_slugs", ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true, using: :btree
  add_index "friendly_id_slugs", ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type", using: :btree
  add_index "friendly_id_slugs", ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id", using: :btree
  add_index "friendly_id_slugs", ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type", using: :btree

  create_table "link_monitors", force: :cascade do |t|
    t.string   "url"
    t.integer  "code"
    t.datetime "failed_at"
    t.datetime "last_failed_at"
    t.integer  "fail_count"
    t.integer  "lcheck_id"
    t.string   "lcheck_type"
  end

  add_index "link_monitors", ["lcheck_type", "lcheck_id"], name: "index_link_monitors_on_lcheck_type_and_lcheck_id", using: :btree

  create_table "materials", force: :cascade do |t|
    t.text     "title"
    t.string   "url"
    t.string   "short_description"
    t.string   "doi"
    t.date     "remote_updated_date"
    t.date     "remote_created_date"
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
    t.text     "long_description"
    t.string   "target_audience",     default: [],                          array: true
    t.string   "keywords",            default: [],                          array: true
    t.string   "authors",             default: [],                          array: true
    t.string   "contributors",        default: [],                          array: true
    t.string   "licence",             default: "notspecified"
    t.string   "difficulty_level",    default: "notspecified"
    t.integer  "content_provider_id"
    t.string   "slug"
    t.integer  "user_id"
    t.date     "last_scraped"
    t.boolean  "scraper_record",      default: false
    t.string   "resource_type",       default: [],                          array: true
  end

  add_index "materials", ["content_provider_id"], name: "index_materials_on_content_provider_id", using: :btree
  add_index "materials", ["slug"], name: "index_materials_on_slug", unique: true, using: :btree
  add_index "materials", ["user_id"], name: "index_materials_on_user_id", using: :btree

  create_table "node_links", force: :cascade do |t|
    t.integer "node_id"
    t.integer "resource_id"
    t.string  "resource_type"
  end

  add_index "node_links", ["node_id"], name: "index_node_links_on_node_id", using: :btree
  add_index "node_links", ["resource_type", "resource_id"], name: "index_node_links_on_resource_type_and_resource_id", using: :btree

  create_table "nodes", force: :cascade do |t|
    t.string   "name"
    t.string   "member_status"
    t.string   "country_code"
    t.string   "home_page"
    t.string   "twitter"
    t.string   "carousel_images",              array: true
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "slug"
    t.integer  "user_id"
    t.text     "image_url"
    t.text     "description"
  end

  add_index "nodes", ["slug"], name: "index_nodes_on_slug", unique: true, using: :btree
  add_index "nodes", ["user_id"], name: "index_nodes_on_user_id", using: :btree

  create_table "package_events", id: false, force: :cascade do |t|
    t.integer  "event_id"
    t.integer  "package_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "id"
  end

  add_index "package_events", ["event_id"], name: "index_package_events_on_event_id", using: :btree
  add_index "package_events", ["package_id"], name: "index_package_events_on_package_id", using: :btree

  create_table "package_materials", id: false, force: :cascade do |t|
    t.integer  "material_id"
    t.integer  "package_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.integer  "id"
  end

  add_index "package_materials", ["material_id"], name: "index_package_materials_on_material_id", using: :btree
  add_index "package_materials", ["package_id"], name: "index_package_materials_on_package_id", using: :btree

  create_table "packages", force: :cascade do |t|
    t.string   "title"
    t.text     "description"
    t.text     "image_url"
    t.boolean  "public",             default: true
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.integer  "user_id"
    t.string   "slug"
    t.string   "keywords",           default: [],                array: true
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
  end

  add_index "packages", ["slug"], name: "index_packages_on_slug", unique: true, using: :btree
  add_index "packages", ["user_id"], name: "index_packages_on_user_id", using: :btree

  create_table "profiles", force: :cascade do |t|
    t.text     "firstname"
    t.text     "surname"
    t.text     "image_url"
    t.text     "email"
    t.text     "website"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "user_id"
    t.string   "slug"
  end

  add_index "profiles", ["slug"], name: "index_profiles_on_slug", unique: true, using: :btree

  create_table "roles", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "title"
  end

  create_table "scientific_topic_links", force: :cascade do |t|
    t.integer "resource_id"
    t.string  "resource_type"
    t.string  "term_uri"
  end

  add_index "scientific_topic_links", ["resource_type", "resource_id"], name: "index_scientific_topic_links_on_resource_type_and_resource_id", using: :btree
  add_index "scientific_topic_links", ["term_uri"], name: "index_scientific_topic_links_on_term_uri", using: :btree

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", unique: true, using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "staff_members", force: :cascade do |t|
    t.string   "name"
    t.string   "role"
    t.string   "email"
    t.text     "image_url"
    t.integer  "node_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
  end

  add_index "staff_members", ["node_id"], name: "index_staff_members_on_node_id", using: :btree

  create_table "stars", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "stars", ["resource_type", "resource_id"], name: "index_stars_on_resource_type_and_resource_id", using: :btree
  add_index "stars", ["user_id"], name: "index_stars_on_user_id", using: :btree

  create_table "subscriptions", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "last_sent_at"
    t.text     "query"
    t.json     "facets"
    t.integer  "frequency"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.string   "subscribable_type"
    t.datetime "last_checked_at"
  end

  add_index "subscriptions", ["user_id"], name: "index_subscriptions_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "username"
    t.integer  "role_id"
    t.integer  "material_id"
    t.string   "authentication_token"
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "failed_attempts",        default: 0,  null: false
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.string   "slug"
    t.string   "provider"
    t.string   "uid"
    t.string   "identity_url"
  end

  add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", using: :btree
  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["identity_url"], name: "index_users_on_identity_url", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["role_id"], name: "index_users_on_role_id", using: :btree
  add_index "users", ["slug"], name: "index_users_on_slug", unique: true, using: :btree
  add_index "users", ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree
  add_index "users", ["username"], name: "index_users_on_username", unique: true, using: :btree

  create_table "widget_logs", force: :cascade do |t|
    t.string   "widget_name"
    t.string   "action"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.text     "data"
    t.json     "params"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "widget_logs", ["resource_type", "resource_id"], name: "index_widget_logs_on_resource_type_and_resource_id", using: :btree

  create_table "workflows", force: :cascade do |t|
    t.string   "title"
    t.string   "description"
    t.integer  "user_id"
    t.json     "workflow_content"
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
    t.string   "slug"
    t.string   "target_audience",     default: [],                          array: true
    t.string   "keywords",            default: [],                          array: true
    t.string   "authors",             default: [],                          array: true
    t.string   "contributors",        default: [],                          array: true
    t.string   "licence",             default: "notspecified"
    t.string   "difficulty_level",    default: "notspecified"
    t.string   "doi"
    t.date     "remote_created_date"
    t.date     "remote_updated_date"
    t.boolean  "hide_child_nodes",    default: false
    t.boolean  "public",              default: true
  end

  add_index "workflows", ["slug"], name: "index_workflows_on_slug", unique: true, using: :btree
  add_index "workflows", ["user_id"], name: "index_workflows_on_user_id", using: :btree

  add_foreign_key "bans", "users"
  add_foreign_key "bans", "users", column: "banner_id"
  add_foreign_key "collaborations", "users"
  add_foreign_key "content_providers", "nodes"
  add_foreign_key "content_providers", "users"
  add_foreign_key "event_materials", "events"
  add_foreign_key "event_materials", "materials"
  add_foreign_key "events", "users"
  add_foreign_key "materials", "content_providers"
  add_foreign_key "materials", "users"
  add_foreign_key "node_links", "nodes"
  add_foreign_key "nodes", "users"
  add_foreign_key "packages", "users"
  add_foreign_key "staff_members", "nodes"
  add_foreign_key "stars", "users"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "users", "roles"
  add_foreign_key "workflows", "users"
end
