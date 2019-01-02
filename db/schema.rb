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

ActiveRecord::Schema.define(version: 2018_12_13_214340) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_stat_statements"
  enable_extension "plpgsql"

  create_table "api_keys", id: :serial, force: :cascade do |t|
    t.string "access_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.datetime "deleted_at"
    t.integer "rate_limit", default: 60
    t.index ["access_token"], name: "index_api_keys_on_access_token"
    t.index ["user_id"], name: "index_api_keys_on_user_id"
  end

  create_table "auth_tokens", id: :serial, force: :cascade do |t|
    t.string "login"
    t.string "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "authorized"
  end

  create_table "contributions", id: :serial, force: :cascade do |t|
    t.integer "repository_id"
    t.integer "repository_user_id"
    t.integer "count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "platform"
    t.index ["repository_id", "repository_user_id"], name: "index_contributions_on_repository_id_and_user_id"
    t.index ["repository_user_id"], name: "index_contributions_on_repository_user_id"
  end

  create_table "dependencies", id: :serial, force: :cascade do |t|
    t.integer "version_id"
    t.integer "project_id"
    t.string "project_name"
    t.string "platform"
    t.string "kind"
    t.boolean "optional", default: false
    t.string "requirements"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_dependencies_on_project_id"
    t.index ["version_id"], name: "index_dependencies_on_version_id"
  end

  create_table "identities", id: :serial, force: :cascade do |t|
    t.string "uid"
    t.string "provider"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "token"
    t.string "nickname"
    t.string "avatar_url"
    t.integer "repository_user_id"
    t.index ["repository_user_id"], name: "index_identities_on_repository_user_id"
    t.index ["uid"], name: "index_identities_on_uid"
    t.index ["user_id"], name: "index_identities_on_user_id"
  end

  create_table "issues", id: :serial, force: :cascade do |t|
    t.integer "repository_id"
    t.string "uuid"
    t.integer "number"
    t.string "state"
    t.string "title"
    t.text "body"
    t.boolean "locked"
    t.integer "comments_count"
    t.datetime "closed_at"
    t.string "labels", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_synced_at"
    t.boolean "pull_request"
    t.string "host_type"
    t.integer "repository_user_id"
    t.index ["repository_id", "uuid"], name: "index_issues_on_repository_id_and_uuid"
  end

  create_table "manifests", id: :serial, force: :cascade do |t|
    t.integer "repository_id"
    t.string "platform"
    t.string "filepath"
    t.string "sha"
    t.string "branch"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "kind"
    t.index ["created_at"], name: "index_manifests_on_created_at"
    t.index ["repository_id"], name: "index_manifests_on_repository_id"
  end

  create_table "project_mutes", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "user_id"], name: "index_project_mutes_on_project_id_and_user_id", unique: true
  end

  create_table "project_suggestions", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.integer "user_id"
    t.string "licenses"
    t.string "repository_url"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status"
  end

  create_table "projects", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "platform"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.text "keywords"
    t.string "homepage"
    t.string "licenses"
    t.string "repository_url"
    t.integer "repository_id"
    t.string "normalized_licenses", default: [], array: true
    t.integer "versions_count", default: 0, null: false
    t.integer "rank", default: 0
    t.datetime "latest_release_published_at"
    t.string "latest_release_number"
    t.integer "pm_id"
    t.string "keywords_array", default: [], array: true
    t.integer "dependents_count", default: 0, null: false
    t.string "language"
    t.string "status"
    t.datetime "last_synced_at"
    t.integer "dependent_repos_count"
    t.integer "runtime_dependencies_count"
    t.integer "score", default: 0, null: false
    t.datetime "score_last_calculated"
    t.string "latest_stable_release_number"
    t.datetime "latest_stable_release_published_at"
    t.index "lower((platform)::text), lower((name)::text)", name: "index_projects_on_platform_and_name_lower"
    t.index ["created_at"], name: "index_projects_on_created_at"
    t.index ["dependents_count"], name: "index_projects_on_dependents_count"
    t.index ["keywords_array"], name: "index_projects_on_keywords_array", using: :gin
    t.index ["platform", "dependents_count"], name: "index_projects_on_platform_and_dependents_count"
    t.index ["platform", "name"], name: "index_projects_on_platform_and_name", unique: true
    t.index ["repository_id"], name: "index_projects_on_repository_id"
    t.index ["updated_at"], name: "index_projects_on_updated_at"
    t.index ["versions_count"], name: "index_projects_on_versions_count"
  end

  create_table "readmes", id: :serial, force: :cascade do |t|
    t.integer "repository_id"
    t.text "html_body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["repository_id"], name: "index_readmes_on_repository_id", unique: true
  end

  create_table "registry_permissions", id: :serial, force: :cascade do |t|
    t.integer "registry_user_id"
    t.integer "project_id"
    t.string "kind"
    t.index ["project_id"], name: "index_registry_permissions_on_project_id"
    t.index ["registry_user_id"], name: "index_registry_permissions_on_registry_user_id"
  end

  create_table "registry_users", id: :serial, force: :cascade do |t|
    t.string "platform"
    t.string "uuid"
    t.string "login"
    t.string "email"
    t.string "name"
    t.string "url"
    t.index ["platform", "uuid"], name: "index_registry_users_on_platform_and_uuid", unique: true
  end

  create_table "repositories", id: :serial, force: :cascade do |t|
    t.string "full_name"
    t.string "description"
    t.boolean "fork"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "pushed_at"
    t.string "homepage"
    t.integer "size"
    t.integer "stargazers_count"
    t.string "language"
    t.boolean "has_issues"
    t.boolean "has_wiki"
    t.boolean "has_pages"
    t.integer "forks_count"
    t.string "mirror_url"
    t.integer "open_issues_count"
    t.string "default_branch"
    t.integer "subscribers_count"
    t.string "uuid"
    t.string "source_name"
    t.string "license"
    t.integer "repository_organisation_id"
    t.boolean "private"
    t.integer "contributions_count", default: 0, null: false
    t.string "has_readme"
    t.string "has_changelog"
    t.string "has_contributing"
    t.string "has_license"
    t.string "has_coc"
    t.string "has_threat_model"
    t.string "has_audit"
    t.string "status"
    t.datetime "last_synced_at"
    t.integer "rank"
    t.string "host_type"
    t.string "host_domain"
    t.string "name"
    t.string "scm"
    t.string "fork_policy"
    t.string "pull_requests_enabled"
    t.string "logo_url"
    t.integer "repository_user_id"
    t.string "keywords", default: [], array: true
    t.index "lower((host_type)::text), lower((full_name)::text)", name: "index_repositories_on_lower_host_type_lower_full_name", unique: true
    t.index "lower((language)::text)", name: "github_repositories_lower_language"
    t.index ["host_type", "uuid"], name: "index_repositories_on_host_type_and_uuid", unique: true
    t.index ["repository_organisation_id"], name: "index_repositories_on_repository_organisation_id"
    t.index ["repository_user_id"], name: "index_repositories_on_repository_user_id"
    t.index ["source_name"], name: "index_repositories_on_source_name"
    t.index ["status"], name: "index_repositories_on_status"
  end

  create_table "repository_dependencies", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.integer "manifest_id"
    t.boolean "optional"
    t.string "project_name"
    t.string "platform"
    t.string "requirements"
    t.string "kind"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "repository_id"
    t.index ["manifest_id"], name: "index_repository_dependencies_on_manifest_id"
    t.index ["project_id"], name: "index_repository_dependencies_on_project_id"
    t.index ["repository_id"], name: "index_repository_dependencies_on_repository_id"
  end

  create_table "repository_maintenance_stats", force: :cascade do |t|
    t.bigint   "repository_id", :index=>{:name=>"index_repository_maintenance_stats_on_repository_id", :order=>{:repository_id=>:asc}}
    t.string   "category"
    t.string   "value"
    t.datetime "created_at",    :null=>false
    t.datetime "updated_at",    :null=>false
  end

  create_table "repository_organisations", id: :serial, force: :cascade do |t|
    t.string "login"
    t.string "uuid"
    t.string "name"
    t.string "blog"
    t.string "email"
    t.string "location"
    t.string "bio"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "hidden", default: false
    t.datetime "last_synced_at"
    t.string "host_type"
    t.index "lower((host_type)::text), lower((login)::text)", name: "index_repository_organisations_on_lower_host_type_lower_login", unique: true
    t.index ["created_at"], name: "index_repository_organisations_on_created_at"
    t.index ["hidden"], name: "index_repository_organisations_on_hidden"
    t.index ["host_type", "uuid"], name: "index_repository_organisations_on_host_type_and_uuid", unique: true
  end

  create_table "repository_permissions", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "repository_id"
    t.boolean "admin"
    t.boolean "push"
    t.boolean "pull"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "repository_id"], name: "user_repo_unique_repository_permissions", unique: true
  end

  create_table "repository_subscriptions", id: :serial, force: :cascade do |t|
    t.integer "repository_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "hook_id"
    t.boolean "include_prerelease", default: true
    t.index ["created_at"], name: "index_repository_subscriptions_on_created_at"
  end

  create_table "repository_users", id: :serial, force: :cascade do |t|
    t.string "uuid"
    t.string "login"
    t.string "user_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "company"
    t.string "blog"
    t.string "location"
    t.boolean "hidden", default: false
    t.datetime "last_synced_at"
    t.string "email"
    t.string "bio"
    t.integer "followers"
    t.integer "following"
    t.string "host_type"
    t.index "lower((host_type)::text), lower((login)::text)", name: "index_repository_users_on_lower_host_type_lower_login", unique: true
    t.index ["created_at"], name: "index_repository_users_on_created_at"
    t.index ["hidden"], name: "index_repository_users_on_hidden"
    t.index ["host_type", "uuid"], name: "index_repository_users_on_host_type_and_uuid", unique: true
  end

  create_table "subscriptions", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "repository_subscription_id"
    t.boolean "include_prerelease", default: true
    t.index ["created_at"], name: "index_subscriptions_on_created_at"
    t.index ["project_id"], name: "index_subscriptions_on_project_id"
    t.index ["user_id", "project_id"], name: "index_subscriptions_on_user_id_and_project_id"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.integer "repository_id"
    t.string "name"
    t.string "sha"
    t.string "kind"
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["repository_id", "name"], name: "index_tags_on_repository_id_and_name"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "currently_syncing", default: false, null: false
    t.datetime "last_synced_at"
    t.boolean "emails_enabled", default: true
    t.boolean "optin", default: false
    t.datetime "last_login_at"
    t.index ["created_at"], name: "index_users_on_created_at"
  end

  create_table "versions", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.string "number"
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "runtime_dependencies_count"
    t.index ["project_id", "number"], name: "index_versions_on_project_id_and_number", unique: true
  end

  create_table "web_hooks", id: :serial, force: :cascade do |t|
    t.integer "repository_id"
    t.integer "user_id"
    t.string "url"
    t.string "last_response"
    t.datetime "last_sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["repository_id"], name: "index_web_hooks_on_repository_id"
  end


  create_view "project_dependent_repositories", materialized: true,  sql_definition: <<-SQL
      SELECT t1.project_id,
      t1.id AS repository_id,
      t1.rank,
      t1.stargazers_count
     FROM (( SELECT repositories.id,
              repositories.rank,
              repositories.stargazers_count,
              repository_dependencies.project_id
             FROM (repositories
               JOIN repository_dependencies ON ((repositories.id = repository_dependencies.repository_id)))
            WHERE (repositories.private = false)
            GROUP BY repositories.id, repository_dependencies.project_id) t1
       JOIN projects ON ((t1.project_id = projects.id)));
  SQL

  add_index "project_dependent_repositories", ["project_id", "rank", "stargazers_count"], name: "index_project_dependent_repos_on_rank", order: { rank: "DESC NULLS LAST", stargazers_count: :desc }
  add_index "project_dependent_repositories", ["project_id", "repository_id"], name: "index_project_dependent_repos_on_proj_id_and_repo_id", unique: true

end
