class Repositories
  class Base
    def self.save(project, include_versions = true)
      mapped_project = mapping(project)
      return false unless mapped_project
      puts "Saving #{mapped_project[:name]}"
      dbproject = Project.find_or_create_by({:name => mapped_project[:name], :platform => self.name.demodulize})
      dbproject.update_attributes(mapped_project.except(:name))

      if include_versions && self::HAS_VERSIONS
        versions(project).each do |version|
          dbproject.versions.find_or_create_by(version)
        end
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
      name = self.name.demodulize
      puts "Importing #{name}"
      before = Time.now.utc
      project_names.each{|name| update(name, include_versions)}
      ActiveRecord::Base.connection.reconnect!
      count = Project.platform(name).where('created_at > ?', before).count
      puts "Imported #{count} new #{name} projects"
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
  end
end
