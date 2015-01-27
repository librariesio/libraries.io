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

ActiveRecord::Schema.define(version: 20150127220301) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "auth_tokens", force: :cascade do |t|
    t.string   "login"
    t.string   "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "github_contributions", force: :cascade do |t|
    t.integer  "github_repository_id"
    t.integer  "github_user_id"
    t.integer  "count"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.string   "platform"
  end

  create_table "github_repositories", force: :cascade do |t|
    t.integer  "project_id"
    t.string   "full_name"
    t.string   "owner_id"
    t.string   "description"
    t.boolean  "fork"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
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
  end

  add_index "github_repositories", ["project_id"], name: "index_github_repositories_on_project_id", using: :btree

  create_table "github_users", force: :cascade do |t|
    t.integer  "github_id"
    t.string   "login"
    t.string   "user_type"
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
  end

  add_index "projects", ["platform"], name: "index_projects_on_platform", using: :btree

  create_table "versions", force: :cascade do |t|
    t.integer  "project_id"
    t.string   "number"
    t.datetime "published_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "versions", ["number"], name: "index_versions_on_number", using: :btree
  add_index "versions", ["project_id"], name: "index_versions_on_project_id", using: :btree

end
