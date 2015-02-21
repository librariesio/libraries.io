namespace :projects do
  task normalize_licenses: :environment do
    Project.where("licenses <> ''").where("normalized_licenses = '{}'").find_each do |project|
      project.normalize_licenses
      project.save
    end
  end

  task recreate_index: :environment do
    # If the index doesn't exists can't be deleted, returns 404, carry on
    Project.__elasticsearch__.client.indices.delete index: 'projects' rescue nil
    Project.__elasticsearch__.create_index! force: true
  end

  task reindex: [:environment, :recreate_index] do
    Project.import query: -> { includes(:github_repository, :versions, :github_contributions) }
  end

  task find_repos_in_homepage: :environment do
    Project.with_homepage.without_repository_url.find_each do |project|
      if homepage_gh = GithubRepository.extract_full_name(project.homepage)
        project.update_attribute(:repository_url, "https://github.com/#{homepage_gh}")
        project.update_github_repo
      end
    end
  end

  task fix_repository_url: :environment do
    Project.with_repository_url.where("repository_url NOT ILIKE 'http%'").find_each do |project|
      if repo_gh = GithubRepository.extract_full_name(project.repository_url)
        project.update_attribute(:repository_url, "https://github.com/#{repo_gh}")
        project.update_github_repo
      end
    end
  end
end
