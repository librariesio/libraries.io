# frozen_string_literal: true

namespace :github do
  desc "Sync github users"
  task sync_users: :environment do
    exit if ENV["READ_ONLY"].present?
    RepositoryUser.visible.where(last_synced_at: nil).limit(50).select("login,host_type").each(&:async_sync)
    RepositoryUser.visible.order("last_synced_at ASC").limit(50).select("login,host_type").each(&:async_sync)
  end

  desc "Sync github orgs"
  task sync_orgs: :environment do
    exit if ENV["READ_ONLY"].present?
    RepositoryOrganisation.visible.order("last_synced_at ASC").limit(50).select("login,host_type").each(&:async_sync)
  end

  desc "Sync github repos"
  task sync_repos: :environment do
    exit if ENV["READ_ONLY"].present?
    scope = Repository.source.open_source.not_removed
    scope.where(last_synced_at: nil).limit(50).each(&:update_all_info_async)
    scope.order("last_synced_at ASC").limit(50).each(&:update_all_info_async)
  end

  desc "Update source rank"
  task update_source_rank: :environment do
    exit if ENV["READ_ONLY"].present?
    Repository.source.not_removed.open_source.where(rank: nil).order("repositories.stargazers_count DESC").limit(500).select("id").each(&:update_source_rank_async)
  end

  desc "Sync github issues"
  task sync_issues: :environment do
    exit if ENV["READ_ONLY"].present?
    scope = Issue.includes(:repository)
    scope.help_wanted.indexable.order("last_synced_at ASC").limit(50).each(&:sync)
    scope.first_pull_request.indexable.order("last_synced_at ASC").limit(50).each(&:sync)
    scope.order("last_synced_at ASC").limit(50).each(&:sync)
  end

  desc "Sync trending github repositories"
  task update_trending: :environment do
    exit if ENV["READ_ONLY"].present?
    trending = Repository.open_source.pushed.maintained.recently_created.hacker_news.limit(30).select("id")
    brand_new = Repository.open_source.pushed.maintained.recently_created.order("created_at DESC").limit(60).select("id")
    (trending + brand_new).uniq.each { |g| RepositoryDownloadWorker.perform_async(g.id) }
  end

  desc "Download all github users"
  task download_all_users: :environment do
    exit if ENV["READ_ONLY"].present?
    since = REDIS.get("githubuserid").to_i

    loop do
      users = AuthToken.client(auto_paginate: false).all_users(since: since)
      users.each do |o|
        if o.type == "Organization"
          RepositoryOrganisation.where(host_type: "GitHub").find_or_create_by(uuid: o.id) do |u|
            u.login = o.login
          end
        else
          RepositoryUser.create_from_host("GitHub", o)
        end
      rescue StandardError
        nil
      end
      since = users.last.id + 1
      REDIS.set("githubuserid", since)
      puts "*" * 20
      puts "#{since} - #{format('%.4f', (since.to_f / 250_000))}%"
      puts "*" * 20
      sleep 0.5
    end
  end

  desc "Update Github V4 API Schema File"
  task :update_github_v4_api_file, [:github_token] => :environment do |_task, args|
    token = args.github_token || ENV["GITHUB_TOKEN"]
    raise ArgumentError, "Github token not found! Pass one into this rake task or define an environment variable GITHUB_TOKEN" if token.nil?

    http = GraphQL::Client::HTTP.new("https://api.github.com/graphql") do
      @@token = token
      def headers(_context)
        # Send Github Token
        { "Authorization": "bearer #{@@token}" }
      end
    end

    GraphQL::Client.dump_schema(http, "config/github_graphql_schema.json")
  end
end
