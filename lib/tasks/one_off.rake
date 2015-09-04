namespace :one_off do
  # put your one off tasks here and delete them once they've been ran
  desc 'fix git urls'
  task fix_git_urls: :environment do
    Project.where('repository_url LIKE ?', 'https://github.com/git+%').find_each do |p|
      p.repository_url.gsub!('https://github.com/git+', 'https://github.com/')
      p.save
    end
  end

  desc 'update user repos'
  task update_user_repos: :environment do
    User.find_each do |user|
      user.update_repo_permissions
      user.adminable_github_repositories.each{|g| g.update_all_info_async user.token }
    end
  end

  desc 'delete duplicate versions'
  task delete_duplicate_versions: :environment do
    versions = Version.find_by_sql('SELECT lower(number) as number, project_id FROM "versions" GROUP BY lower(number),project_id HAVING count(*) > 1')

    versions.each do |version|
      dupes = Version.where(project_id: version.project_id).where('lower(number) = ?', version.number.downcase).order('published_at')
      dupes.each_with_index do |v, index|
        next if index.zero?
        v.destroy
      end
    end
  end


end
