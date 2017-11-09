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

ActiveRecord::Schema.define(version: 20171019174602) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "pg_stat_statements"

  create_table "api_keys", force: :cascade do |t|
    t.string   "access_token", :index=>{:name=>"index_api_keys_on_access_token"}
    t.datetime "created_at",   :null=>false
    t.datetime "updated_at",   :null=>false
    t.integer  "user_id",      :index=>{:name=>"index_api_keys_on_user_id"}
    t.datetime "deleted_at"
    t.integer  "rate_limit",   :default=>60
  end

  create_table "auth_tokens", force: :cascade do |t|
    t.string   "login"
    t.string   "token"
    t.datetime "created_at", :null=>false
    t.datetime "updated_at", :null=>false
    t.boolean  "authorized"
  end

  create_table "contributions", force: :cascade do |t|
    t.integer  "repository_id",      :index=>{:name=>"index_contributions_on_repository_id_and_user_id", :with=>["repository_user_id"]}
    t.integer  "repository_user_id", :index=>{:name=>"index_contributions_on_repository_user_id"}
    t.integer  "count"
    t.datetime "created_at",         :null=>false
    t.datetime "updated_at",         :null=>false
    t.string   "platform"
  end

  create_table "dependencies", force: :cascade do |t|
    t.integer  "version_id",   :index=>{:name=>"index_dependencies_on_version_id"}
    t.integer  "project_id",   :index=>{:name=>"index_dependencies_on_project_id"}
    t.string   "project_name"
    t.string   "platform"
    t.string   "kind"
    t.boolean  "optional",     :default=>false
    t.string   "requirements"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "identities", force: :cascade do |t|
    t.string   "uid",                :index=>{:name=>"index_identities_on_uid"}
    t.string   "provider"
    t.integer  "user_id",            :index=>{:name=>"index_identities_on_user_id"}
    t.datetime "created_at",         :null=>false
    t.datetime "updated_at",         :null=>false
    t.string   "token"
    t.string   "nickname"
    t.string   "avatar_url"
    t.integer  "repository_user_id", :index=>{:name=>"index_identities_on_repository_user_id"}
  end

  create_table "issues", force: :cascade do |t|
    t.integer  "repository_id",      :index=>{:name=>"index_issues_on_repository_id"}
    t.string   "uuid"
    t.integer  "number"
    t.string   "state"
    t.string   "title"
    t.text     "body"
    t.boolean  "locked"
    t.integer  "comments_count"
    t.datetime "closed_at"
    t.string   "labels",             :default=>[], :array=>true
    t.datetime "created_at",         :null=>false
    t.datetime "updated_at",         :null=>false
    t.datetime "last_synced_at"
    t.boolean  "pull_request"
    t.string   "host_type"
    t.integer  "repository_user_id"
  end

  create_table "manifests", force: :cascade do |t|
    t.integer  "repository_id", :index=>{:name=>"index_manifests_on_repository_id"}
    t.string   "platform"
    t.string   "filepath"
    t.string   "sha"
    t.string   "branch"
    t.datetime "created_at",    :null=>false, :index=>{:name=>"index_manifests_on_created_at"}
    t.datetime "updated_at",    :null=>false
    t.string   "kind"
  end

  create_table "project_mutes", force: :cascade do |t|
    t.integer  "user_id",    :null=>false
    t.integer  "project_id", :null=>false, :index=>{:name=>"index_project_mutes_on_project_id_and_user_id", :with=>["user_id"], :unique=>true}
    t.datetime "created_at", :null=>false
    t.datetime "updated_at", :null=>false
  end

  create_table "project_suggestions", force: :cascade do |t|
    t.integer  "project_id"
    t.integer  "user_id"
    t.string   "licenses"
    t.string   "repository_url"
    t.text     "notes"
    t.datetime "created_at",     :null=>false
    t.datetime "updated_at",     :null=>false
    t.string   "status"
  end

  create_table "projects", force: :cascade do |t|
    t.string   "name"
    t.string   "platform",                    :index=>{:name=>"index_projects_on_platform_and_name", :with=>["name"], :unique=>true}
    t.datetime "created_at",                  :index=>{:name=>"index_projects_on_created_at"}
    t.datetime "updated_at",                  :index=>{:name=>"index_projects_on_updated_at"}
    t.text     "description"
    t.text     "keywords"
    t.string   "homepage"
    t.string   "licenses"
    t.string   "repository_url"
    t.integer  "repository_id",               :index=>{:name=>"index_projects_on_repository_id"}
    t.string   "normalized_licenses",         :default=>[], :array=>true
    t.integer  "versions_count",              :default=>0, :null=>false, :index=>{:name=>"index_projects_on_versions_count"}
    t.integer  "rank",                        :default=>0
    t.datetime "latest_release_published_at"
    t.string   "latest_release_number"
    t.integer  "pm_id"
    t.string   "keywords_array",              :default=>[], :array=>true, :index=>{:name=>"index_projects_on_keywords_array", :using=>:gin}
    t.integer  "dependents_count",            :default=>0, :null=>false, :index=>{:name=>"index_projects_on_dependents_count"}
    t.string   "language"
    t.string   "status"
    t.datetime "last_synced_at"
    t.integer  "dependent_repos_count"

    t.index ["platform", "name"], :name=>"index_projects_on_platform_and_name_lower", :case_sensitive=>false
  end

  create_table "readmes", force: :cascade do |t|
    t.integer  "repository_id", :index=>{:name=>"index_readmes_on_repository_id", :unique=>true}
    t.text     "html_body"
    t.datetime "created_at",    :null=>false
    t.datetime "updated_at",    :null=>false
  end

  create_table "repositories", force: :cascade do |t|
    t.string   "full_name"
    t.string   "description"
    t.boolean  "fork"
    t.datetime "created_at",                 :null=>false
    t.datetime "updated_at",                 :null=>false
    t.datetime "pushed_at"
    t.string   "homepage"
    t.integer  "size"
    t.integer  "stargazers_count"
    t.string   "language",                   :index=>{:name=>"github_repositories_lower_language", :case_sensitive=>false}
    t.boolean  "has_issues"
    t.boolean  "has_wiki"
    t.boolean  "has_pages"
    t.integer  "forks_count"
    t.string   "mirror_url"
    t.integer  "open_issues_count"
    t.string   "default_branch"
    t.integer  "subscribers_count"
    t.string   "uuid"
    t.string   "source_name",                :index=>{:name=>"index_repositories_on_source_name"}
    t.string   "license"
    t.integer  "repository_organisation_id", :index=>{:name=>"index_repositories_on_repository_organisation_id"}
    t.boolean  "private"
    t.integer  "contributions_count",        :default=>0, :null=>false
    t.string   "has_readme"
    t.string   "has_changelog"
    t.string   "has_contributing"
    t.string   "has_license"
    t.string   "has_coc"
    t.string   "has_threat_model"
    t.string   "has_audit"
    t.string   "status",                     :index=>{:name=>"index_repositories_on_status"}
    t.datetime "last_synced_at"
    t.integer  "rank"
    t.string   "host_type",                  :index=>{:name=>"index_repositories_on_host_type_and_full_name", :with=>["full_name"], :unique=>true, :case_sensitive=>false}
    t.string   "host_domain"
    t.string   "name"
    t.string   "scm"
    t.string   "fork_policy"
    t.string   "pull_requests_enabled"
    t.string   "logo_url"
    t.integer  "repository_user_id",         :index=>{:name=>"index_repositories_on_repository_user_id"}
    t.string   "keywords",                   :default=>[], :array=>true

    t.index ["host_type", "uuid"], :name=>"index_repositories_on_host_type_and_uuid", :unique=>true
  end

  create_table "repository_dependencies", force: :cascade do |t|
    t.integer  "project_id",   :index=>{:name=>"index_repository_dependencies_on_project_id"}
    t.integer  "manifest_id",  :index=>{:name=>"index_repository_dependencies_on_manifest_id"}
    t.boolean  "optional"
    t.string   "project_name"
    t.string   "platform"
    t.string   "requirements"
    t.string   "kind"
    t.datetime "created_at",   :null=>false
    t.datetime "updated_at",   :null=>false
  end

  create_table "repository_organisations", force: :cascade do |t|
    t.string   "login"
    t.string   "uuid"
    t.string   "name"
    t.string   "blog"
    t.string   "email"
    t.string   "location"
    t.string   "bio"
    t.datetime "created_at",     :null=>false, :index=>{:name=>"index_repository_organisations_on_created_at"}
    t.datetime "updated_at",     :null=>false
    t.boolean  "hidden",         :default=>false, :index=>{:name=>"index_repository_organisations_on_hidden"}
    t.datetime "last_synced_at"
    t.string   "host_type",      :index=>{:name=>"index_repository_organisations_on_host_type_and_login", :with=>["login"], :unique=>true, :case_sensitive=>false}

    t.index ["host_type", "uuid"], :name=>"index_repository_organisations_on_host_type_and_uuid", :unique=>true
  end

  create_table "repository_permissions", force: :cascade do |t|
    t.integer  "user_id",       :index=>{:name=>"user_repo_unique_repository_permissions", :with=>["repository_id"], :unique=>true}
    t.integer  "repository_id"
    t.boolean  "admin"
    t.boolean  "push"
    t.boolean  "pull"
    t.datetime "created_at",    :null=>false
    t.datetime "updated_at",    :null=>false
  end

  create_table "repository_subscriptions", force: :cascade do |t|
    t.integer  "repository_id"
    t.integer  "user_id"
    t.datetime "created_at",         :null=>false, :index=>{:name=>"index_repository_subscriptions_on_created_at"}
    t.datetime "updated_at",         :null=>false
    t.integer  "hook_id"
    t.boolean  "include_prerelease", :default=>true
  end

  create_table "repository_users", force: :cascade do |t|
    t.string   "uuid"
    t.string   "login"
    t.string   "user_type"
    t.datetime "created_at",     :null=>false, :index=>{:name=>"index_repository_users_on_created_at"}
    t.datetime "updated_at",     :null=>false
    t.string   "name"
    t.string   "company"
    t.string   "blog"
    t.string   "location"
    t.boolean  "hidden",         :default=>false, :index=>{:name=>"index_repository_users_on_hidden"}
    t.datetime "last_synced_at"
    t.string   "email"
    t.string   "bio"
    t.integer  "followers"
    t.integer  "following"
    t.string   "host_type",      :index=>{:name=>"index_repository_users_on_host_type_and_login", :with=>["login"], :unique=>true, :case_sensitive=>false}

    t.index ["host_type", "uuid"], :name=>"index_repository_users_on_host_type_and_uuid", :unique=>true
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer  "project_id",                 :index=>{:name=>"index_subscriptions_on_project_id"}
    t.integer  "user_id",                    :index=>{:name=>"index_subscriptions_on_user_id_and_project_id", :with=>["project_id"]}
    t.datetime "created_at",                 :null=>false, :index=>{:name=>"index_subscriptions_on_created_at"}
    t.datetime "updated_at",                 :null=>false
    t.integer  "repository_subscription_id"
    t.boolean  "include_prerelease",         :default=>true
  end

  create_table "tags", force: :cascade do |t|
    t.integer  "repository_id", :index=>{:name=>"index_tags_on_repository_id_and_name", :with=>["name"]}
    t.string   "name"
    t.string   "sha"
    t.string   "kind"
    t.datetime "published_at"
    t.datetime "created_at",    :null=>false
    t.datetime "updated_at",    :null=>false
  end

  create_table "users", force: :cascade do |t|
    t.string   "email"
    t.datetime "created_at",        :index=>{:name=>"index_users_on_created_at"}
    t.datetime "updated_at"
    t.boolean  "currently_syncing", :default=>false, :null=>false
    t.datetime "last_synced_at"
    t.boolean  "emails_enabled",    :default=>true
    t.boolean  "optin",             :default=>false
  end

  create_table "versions", force: :cascade do |t|
    t.integer  "project_id",   :index=>{:name=>"index_versions_on_project_id_and_number", :with=>["number"], :unique=>true}
    t.string   "number"
    t.datetime "published_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "web_hooks", force: :cascade do |t|
    t.integer  "repository_id", :index=>{:name=>"index_web_hooks_on_repository_id"}
    t.integer  "user_id"
    t.string   "url"
    t.string   "last_response"
    t.datetime "last_sent_at"
    t.datetime "created_at",    :null=>false
    t.datetime "updated_at",    :null=>false
  end

end
