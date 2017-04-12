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

ActiveRecord::Schema.define(version: 20170411164230) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "pg_stat_statements"

  create_table "api_keys", force: :cascade do |t|
    t.string   "access_token"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.integer  "user_id"
    t.datetime "deleted_at"
    t.integer  "rate_limit",   default: 60
    t.index ["access_token"], name: "index_api_keys_on_access_token", using: :btree
    t.index ["user_id"], name: "index_api_keys_on_user_id", using: :btree
  end

  create_table "auth_tokens", force: :cascade do |t|
    t.string   "login"
    t.string   "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "contributions", force: :cascade do |t|
    t.integer  "repository_id"
    t.integer  "repository_user_id"
    t.integer  "count"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.string   "platform"
    t.index ["repository_id", "repository_user_id"], name: "index_contributions_on_repository_id_and_user_id", using: :btree
    t.index ["repository_user_id"], name: "index_contributions_on_repository_user_id", using: :btree
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
    t.index ["project_id"], name: "index_dependencies_on_project_id", using: :btree
    t.index ["version_id"], name: "index_dependencies_on_version_id", using: :btree
  end

  create_table "identities", force: :cascade do |t|
    t.string   "uid"
    t.string   "provider"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "token"
    t.string   "nickname"
    t.string   "avatar_url"
    t.index ["user_id"], name: "index_identities_on_user_id", using: :btree
  end

  create_table "issues", force: :cascade do |t|
    t.integer  "repository_id"
    t.integer  "github_id"
    t.integer  "number"
    t.string   "state"
    t.string   "title"
    t.text     "body"
    t.integer  "repository_user_id"
    t.boolean  "locked"
    t.integer  "comments_count"
    t.datetime "closed_at"
    t.string   "labels",             default: [],              array: true
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.datetime "last_synced_at"
    t.boolean  "pull_request"
    t.index ["repository_id"], name: "index_issues_on_repository_id", using: :btree
  end

  create_table "manifests", force: :cascade do |t|
    t.integer  "repository_id"
    t.string   "platform"
    t.string   "filepath"
    t.string   "sha"
    t.string   "branch"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.string   "kind"
    t.index ["created_at"], name: "index_manifests_on_created_at", using: :btree
    t.index ["repository_id"], name: "index_manifests_on_repository_id", using: :btree
  end

  create_table "payola_affiliates", force: :cascade do |t|
    t.string   "code"
    t.string   "email"
    t.integer  "percent"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "payola_coupons", force: :cascade do |t|
    t.string   "code"
    t.integer  "percent_off"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",      default: true
  end

  create_table "payola_sales", force: :cascade do |t|
    t.string   "email",                limit: 191
    t.string   "guid",                 limit: 191
    t.integer  "product_id"
    t.string   "product_type",         limit: 100
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state"
    t.string   "stripe_id"
    t.string   "stripe_token"
    t.string   "card_last4"
    t.date     "card_expiration"
    t.string   "card_type"
    t.text     "error"
    t.integer  "amount"
    t.integer  "fee_amount"
    t.integer  "coupon_id"
    t.boolean  "opt_in"
    t.integer  "download_count"
    t.integer  "affiliate_id"
    t.text     "customer_address"
    t.text     "business_address"
    t.string   "stripe_customer_id",   limit: 191
    t.string   "currency"
    t.text     "signed_custom_fields"
    t.integer  "owner_id"
    t.string   "owner_type",           limit: 100
    t.index ["coupon_id"], name: "index_payola_sales_on_coupon_id", using: :btree
    t.index ["email"], name: "index_payola_sales_on_email", using: :btree
    t.index ["guid"], name: "index_payola_sales_on_guid", using: :btree
    t.index ["owner_id", "owner_type"], name: "index_payola_sales_on_owner_id_and_owner_type", using: :btree
    t.index ["product_id", "product_type"], name: "index_payola_sales_on_product", using: :btree
    t.index ["stripe_customer_id"], name: "index_payola_sales_on_stripe_customer_id", using: :btree
  end

  create_table "payola_stripe_webhooks", force: :cascade do |t|
    t.string   "stripe_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "payola_subscriptions", force: :cascade do |t|
    t.string   "plan_type"
    t.integer  "plan_id"
    t.datetime "start"
    t.string   "status"
    t.string   "owner_type"
    t.integer  "owner_id"
    t.string   "stripe_customer_id"
    t.boolean  "cancel_at_period_end"
    t.datetime "current_period_start"
    t.datetime "current_period_end"
    t.datetime "ended_at"
    t.datetime "trial_start"
    t.datetime "trial_end"
    t.datetime "canceled_at"
    t.integer  "quantity"
    t.string   "stripe_id"
    t.string   "stripe_token"
    t.string   "card_last4"
    t.date     "card_expiration"
    t.string   "card_type"
    t.text     "error"
    t.string   "state"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "currency"
    t.integer  "amount"
    t.string   "guid",                 limit: 191
    t.string   "stripe_status"
    t.integer  "affiliate_id"
    t.string   "coupon"
    t.text     "signed_custom_fields"
    t.text     "customer_address"
    t.text     "business_address"
    t.integer  "setup_fee"
    t.decimal  "tax_percent",                      precision: 4, scale: 2
    t.index ["guid"], name: "index_payola_subscriptions_on_guid", using: :btree
  end

  create_table "project_mutes", force: :cascade do |t|
    t.integer  "user_id",    null: false
    t.integer  "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "user_id"], name: "index_project_mutes_on_project_id_and_user_id", unique: true, using: :btree
  end

  create_table "project_suggestions", force: :cascade do |t|
    t.integer  "project_id"
    t.integer  "user_id"
    t.string   "licenses"
    t.string   "repository_url"
    t.text     "notes"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.string   "status"
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
    t.integer  "repository_id"
    t.string   "normalized_licenses",         default: [],              array: true
    t.integer  "versions_count",              default: 0,  null: false
    t.integer  "rank",                        default: 0
    t.datetime "latest_release_published_at"
    t.string   "latest_release_number"
    t.integer  "pm_id"
    t.string   "keywords_array",              default: [],              array: true
    t.integer  "dependents_count",            default: 0,  null: false
    t.string   "language"
    t.string   "status"
    t.datetime "last_synced_at"
    t.integer  "dependent_repos_count"
    t.index "lower((name)::text)", name: "projects_lower_name", using: :btree
    t.index "lower((platform)::text)", name: "projects_lower_platform", using: :btree
    t.index ["created_at"], name: "index_projects_on_created_at", using: :btree
    t.index ["dependents_count"], name: "index_projects_on_dependents_count", using: :btree
    t.index ["keywords_array"], name: "index_projects_on_keywords_array", using: :gin
    t.index ["name", "platform"], name: "index_projects_on_name_and_platform", using: :btree
    t.index ["repository_id"], name: "index_projects_on_repository_id", using: :btree
    t.index ["updated_at"], name: "index_projects_on_updated_at", using: :btree
    t.index ["versions_count"], name: "index_projects_on_versions_count", using: :btree
  end

  create_table "readmes", force: :cascade do |t|
    t.integer  "repository_id"
    t.text     "html_body"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.index ["repository_id"], name: "index_readmes_on_repository_id", unique: true, using: :btree
  end

  create_table "repositories", force: :cascade do |t|
    t.string   "full_name"
    t.integer  "owner_id"
    t.string   "description"
    t.boolean  "fork"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
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
    t.string   "uuid"
    t.string   "source_name"
    t.string   "license"
    t.integer  "repository_organisation_id"
    t.boolean  "private"
    t.integer  "contributions_count",        default: 0, null: false
    t.string   "has_readme"
    t.string   "has_changelog"
    t.string   "has_contributing"
    t.string   "has_license"
    t.string   "has_coc"
    t.string   "has_threat_model"
    t.string   "has_audit"
    t.string   "status"
    t.datetime "last_synced_at"
    t.integer  "rank"
    t.string   "host_type"
    t.string   "host_domain"
    t.string   "name"
    t.string   "scm"
    t.string   "fork_policy"
    t.string   "pull_requests_enabled"
    t.string   "logo_url"
    t.index "lower((full_name)::text)", name: "index_github_repositories_on_lowercase_full_name", unique: true, using: :btree
    t.index "lower((language)::text)", name: "github_repositories_lower_language", using: :btree
    t.index ["owner_id"], name: "index_repositories_on_owner_id", using: :btree
    t.index ["repository_organisation_id"], name: "index_repositories_on_repository_organisation_id", using: :btree
    t.index ["source_name"], name: "index_repositories_on_source_name", using: :btree
    t.index ["status"], name: "index_repositories_on_status", using: :btree
    t.index ["uuid"], name: "index_repositories_on_uuid", unique: true, using: :btree
  end

  create_table "repository_dependencies", force: :cascade do |t|
    t.integer  "project_id"
    t.integer  "manifest_id"
    t.boolean  "optional"
    t.string   "project_name"
    t.string   "platform"
    t.string   "requirements"
    t.string   "kind"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["manifest_id"], name: "index_repository_dependencies_on_manifest_id", using: :btree
    t.index ["project_id"], name: "index_repository_dependencies_on_project_id", using: :btree
  end

  create_table "repository_organisations", force: :cascade do |t|
    t.string   "login"
    t.integer  "uuid"
    t.string   "name"
    t.string   "blog"
    t.string   "email"
    t.string   "location"
    t.string   "bio"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.boolean  "hidden",         default: false
    t.datetime "last_synced_at"
    t.string   "host_type"
    t.index "lower((login)::text)", name: "index_github_organisations_on_lowercase_login", unique: true, using: :btree
    t.index ["created_at"], name: "index_repository_organisations_on_created_at", using: :btree
    t.index ["hidden"], name: "index_repository_organisations_on_hidden", using: :btree
    t.index ["uuid"], name: "index_repository_organisations_on_uuid", unique: true, using: :btree
  end

  create_table "repository_permissions", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "repository_id"
    t.boolean  "admin"
    t.boolean  "push"
    t.boolean  "pull"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.index ["user_id", "repository_id"], name: "user_repo_unique_repository_permissions", unique: true, using: :btree
  end

  create_table "repository_subscriptions", force: :cascade do |t|
    t.integer  "repository_id"
    t.integer  "user_id"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.integer  "hook_id"
    t.boolean  "include_prerelease", default: true
    t.index ["created_at"], name: "index_repository_subscriptions_on_created_at", using: :btree
  end

  create_table "repository_users", force: :cascade do |t|
    t.integer  "uuid"
    t.string   "login"
    t.string   "user_type"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.string   "name"
    t.string   "company"
    t.string   "blog"
    t.string   "location"
    t.boolean  "hidden",         default: false
    t.datetime "last_synced_at"
    t.string   "email"
    t.string   "bio"
    t.integer  "followers"
    t.integer  "following"
    t.string   "host_type"
    t.index "lower((login)::text)", name: "github_users_lower_login", using: :btree
    t.index "lower((login)::text)", name: "index_github_users_on_lowercase_login", unique: true, using: :btree
    t.index ["created_at"], name: "index_repository_users_on_created_at", using: :btree
    t.index ["hidden"], name: "index_repository_users_on_hidden", using: :btree
    t.index ["login"], name: "index_repository_users_on_login", using: :btree
    t.index ["uuid"], name: "index_repository_users_on_uuid", unique: true, using: :btree
  end

  create_table "subscription_plans", force: :cascade do |t|
    t.integer  "amount"
    t.string   "interval"
    t.string   "stripe_id"
    t.string   "name"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.integer  "repo_count"
    t.boolean  "hidden",     default: false
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer  "project_id"
    t.integer  "user_id"
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.integer  "repository_subscription_id"
    t.boolean  "include_prerelease",         default: true
    t.index ["created_at"], name: "index_subscriptions_on_created_at", using: :btree
    t.index ["project_id"], name: "index_subscriptions_on_project_id", using: :btree
    t.index ["user_id", "project_id"], name: "index_subscriptions_on_user_id_and_project_id", using: :btree
  end

  create_table "tags", force: :cascade do |t|
    t.integer  "repository_id"
    t.string   "name"
    t.string   "sha"
    t.string   "kind"
    t.datetime "published_at"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.index ["repository_id", "name"], name: "index_tags_on_repository_id_and_name", using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "currently_syncing", default: false, null: false
    t.datetime "last_synced_at"
    t.boolean  "emails_enabled",    default: true
    t.index ["created_at"], name: "index_users_on_created_at", using: :btree
  end

  create_table "versions", force: :cascade do |t|
    t.integer  "project_id"
    t.string   "number"
    t.datetime "published_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["project_id", "number"], name: "index_versions_on_project_id_and_number", unique: true, using: :btree
  end

  create_table "web_hooks", force: :cascade do |t|
    t.integer  "repository_id"
    t.integer  "user_id"
    t.string   "url"
    t.string   "last_response"
    t.datetime "last_sent_at"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.index ["repository_id"], name: "index_web_hooks_on_repository_id", using: :btree
  end

end
