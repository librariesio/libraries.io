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

ActiveRecord::Schema.define(version: 20150418132633) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "api_keys", force: :cascade do |t|
    t.string   "access_token"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "auth_tokens", force: :cascade do |t|
    t.string   "login"
    t.string   "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "dependencies", force: :cascade do |t|
    t.integer  "version_id"
    t.integer  "project_id"
    t.string   "project_name"
    t.string   "platform"
    t.string   "kind"
    t.boolean  "optional",     default: false
    t.string   "requirements"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "dependencies", ["created_at"], name: "index_dependencies_on_created_at", using: :btree
  add_index "dependencies", ["platform", "project_name"], name: "index_dependencies_on_platform_and_project_name", using: :btree
  add_index "dependencies", ["project_id"], name: "index_dependencies_on_project_id", using: :btree
  add_index "dependencies", ["version_id"], name: "index_dependencies_on_version_id", using: :btree

  create_table "github_contributions", force: :cascade do |t|
    t.integer  "github_repository_id"
    t.integer  "github_user_id"
    t.integer  "count"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.string   "platform"
  end

  add_index "github_contributions", ["created_at"], name: "index_github_contributions_on_created_at", using: :btree
  add_index "github_contributions", ["github_repository_id"], name: "index_github_contributions_on_github_repository_id", using: :btree
  add_index "github_contributions", ["github_user_id"], name: "index_github_contributions_on_github_user_id", using: :btree
  add_index "github_contributions", ["platform"], name: "index_github_contributions_on_platform", using: :btree

  create_table "github_organisations", force: :cascade do |t|
    t.string   "login"
    t.integer  "github_id"
    t.string   "name"
    t.string   "blog"
    t.string   "email"
    t.string   "location"
    t.string   "description"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "github_organisations", ["github_id"], name: "index_github_organisations_on_github_id", using: :btree
  add_index "github_organisations", ["login"], name: "index_github_organisations_on_login", using: :btree

  create_table "github_repositories", force: :cascade do |t|
    t.string   "full_name"
    t.integer  "owner_id"
    t.string   "description"
    t.boolean  "fork"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.datetime "pushed_at"
    t.string   "homepage"
    t.integer  "size"
    t.integer  "stargazers_count"
    t.string   "language"
    t.boolean  "has_issues"
    t.boolean  "has_wiki"
    t.boolean  "has_pages"
    t.integer  "forks_count"
    t.string   "mirror_url"
    t.integer  "open_issues_count"
    t.string   "default_branch"
    t.integer  "subscribers_count"
    t.integer  "github_id"
    t.string   "source_name"
    t.string   "license"
    t.integer  "github_organisation_id"
  end

  add_index "github_repositories", ["created_at"], name: "index_github_repositories_on_created_at", using: :btree
  add_index "github_repositories", ["full_name"], name: "index_github_repositories_on_full_name", using: :btree
  add_index "github_repositories", ["github_organisation_id"], name: "index_github_repositories_on_github_organisation_id", using: :btree
  add_index "github_repositories", ["owner_id"], name: "index_github_repositories_on_owner_id", using: :btree

  create_table "github_tags", force: :cascade do |t|
    t.integer  "github_repository_id"
    t.string   "name"
    t.string   "sha"
    t.string   "kind"
    t.datetime "published_at"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "github_tags", ["github_repository_id", "name"], name: "index_github_tags_on_github_repository_id_and_name", using: :btree
  add_index "github_tags", ["github_repository_id"], name: "index_github_tags_on_github_repository_id", using: :btree
  add_index "github_tags", ["name"], name: "index_github_tags_on_name", using: :btree

  create_table "github_users", force: :cascade do |t|
    t.integer  "github_id"
    t.string   "login"
    t.string   "user_type"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.string   "name"
    t.string   "company"
    t.string   "blog"
    t.string   "location"
    t.boolean  "hidden",     default: false
  end

  add_index "github_users", ["created_at"], name: "index_github_users_on_created_at", using: :btree
  add_index "github_users", ["github_id"], name: "index_github_users_on_github_id", using: :btree
  add_index "github_users", ["hidden"], name: "index_github_users_on_hidden", using: :btree
  add_index "github_users", ["login"], name: "index_github_users_on_login", using: :btree

  create_table "manifests", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "file_name"
    t.string   "url"
    t.text     "contents"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "projects", force: :cascade do |t|
    t.string   "name"
    t.string   "platform"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
    t.text     "keywords"
    t.string   "homepage"
    t.string   "licenses"
    t.string   "repository_url"
    t.integer  "github_repository_id"
    t.string   "normalized_licenses",         default: [],              array: true
    t.integer  "versions_count",              default: 0,  null: false
    t.integer  "rank",                        default: 0
    t.datetime "latest_release_published_at"
    t.string   "latest_release_number"
  end

  add_index "projects", ["created_at"], name: "index_projects_on_created_at", using: :btree
  add_index "projects", ["github_repository_id"], name: "index_projects_on_github_repository_id", using: :btree
  add_index "projects", ["name", "platform"], name: "index_projects_on_name_and_platform", using: :btree
  add_index "projects", ["platform"], name: "index_projects_on_platform", using: :btree
  add_index "projects", ["updated_at"], name: "index_projects_on_updated_at", using: :btree
  add_index "projects", ["versions_count"], name: "index_projects_on_versions_count", using: :btree

  create_table "readmes", force: :cascade do |t|
    t.integer  "github_repository_id"
    t.text     "html_body"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "readmes", ["created_at"], name: "index_readmes_on_created_at", using: :btree
  add_index "readmes", ["github_repository_id"], name: "index_readmes_on_github_repository_id", using: :btree

  create_table "subscriptions", force: :cascade do |t|
    t.integer  "project_id"
    t.integer  "user_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.integer  "manifest_id"
  end

  add_index "subscriptions", ["created_at"], name: "index_subscriptions_on_created_at", using: :btree
  add_index "subscriptions", ["user_id", "project_id"], name: "index_subscriptions_on_user_id_and_project_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "uid",               null: false
    t.string   "nickname",          null: false
    t.string   "gravatar_id"
    t.string   "token"
    t.string   "name"
    t.string   "blog"
    t.string   "location"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "public_repo_token"
  end

  add_index "users", ["created_at"], name: "index_users_on_created_at", using: :btree
  add_index "users", ["nickname"], name: "index_users_on_nickname", unique: true, using: :btree

  create_table "versions", force: :cascade do |t|
    t.integer  "project_id"
    t.string   "number"
    t.datetime "published_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "versions", ["created_at"], name: "index_versions_on_created_at", using: :btree
  add_index "versions", ["number"], name: "index_versions_on_number", using: :btree
  add_index "versions", ["project_id"], name: "index_versions_on_project_id", using: :btree
  add_index "versions", ["published_at"], name: "index_versions_on_published_at", using: :btree

end
