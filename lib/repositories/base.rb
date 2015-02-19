class Repositories
  class Base
    def self.save(project, include_versions = true)
      mapped_project = mapping(project)
      return false unless mapped_project
      puts "Saving #{mapped_project[:name]}"
      dbproject = Project.find_or_initialize_by({:name => mapped_project[:name], :platform => self.name.demodulize})
      if dbproject.new_record?
        dbproject.assign_attributes(mapped_project.except(:name))
        dbproject.save
      else
        dbproject.update_attributes(mapped_project.except(:name))
      end

      if include_versions && self::HAS_VERSIONS
        versions(project).each do |version|
          dbproject.versions.find_or_create_by(version)
        end
      end

      if self::HAS_DEPENDENCIES
        save_dependencies(mapped_project[:name])
      end

      dbproject
    end

    def self.update(name, include_versions = true)
      begin
        save(project(name), include_versions)
      rescue SystemExit, Interrupt
        exit 0
      rescue Exception => e
        p name
        p e
        # raise e
      end
    end

    def self.import(include_versions = true)
      project_names.each { |name| update(name, include_versions) }
    end

    def self.import_recent
      recent_names.each { |name| update(name) }
    end

    def self.new_names
      names = project_names
      names - Project.platform(self.name.demodulize).where(:name => names).pluck('name')
    end

    def self.import_new
      new_names.each { |name| update(name) }
    end

    def self.save_dependencies(name)
      proj = Project.find_by(name: name, platform: self.name.demodulize)
      proj.versions.each do |version|
        deps = dependencies(name, version.number)
        next unless deps.any? && version.dependencies.empty?
        deps.each do |dep|
          version.dependencies.create(dep) unless version.dependencies.find_by_project_name dep[:project_name]
        end
      end
    end

    def self.download_dependencies
      project_names.each { |name| save_dependencies(name) }
    end

    def self.dependencies(_name, _version)
      []
    end

    def self.get(url, options = {})
      Oj.load(get_raw(url, options))
    end

    def self.get_raw(url, options = {})
      Typhoeus.get(url, options).body
    end

    def self.get_html(url, options = {})
      Nokogiri::HTML(get_raw(url, options))
    end

    def self.get_json(url)
      get(url, headers: { 'Accept' => "application/json"})
    end

    def self.repo_fallback(repo, homepage)
      repo = '' if repo.nil?
      homepage = '' if homepage.nil?
      repo_gh = GithubRepository.extract_full_name(repo)
      homepage_gh = GithubRepository.extract_full_name(homepage)
      if repo_gh.present?
        return "https://github.com/#{repo_gh}"
      elsif homepage_gh.present?
        return "https://github.com/#{homepage_gh}"
      else
        repo
      end
    end
  end
end
