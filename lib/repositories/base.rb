class Repositories
  class Base
    def self.save(project)
      mapped_project = mapping(project)
      return false unless mapped_project
      dbproject = Project.find_or_create_by({:name => mapped_project[:name], :platform => self.name.demodulize})
      dbproject.update_attributes(mapped_project.except(:name))

      if self::HAS_VERSIONS
        versions(project).each do |version|
          dbproject.versions.find_or_create_by(version)
        end
      end

      dbproject
    end

    def self.update(name)
      begin
        save(project(name))
      rescue Exception => e
        p name
        raise e
      end
    end

    def self.import
      Parallel.each(project_names){|name| update(name) }
    end

    def self.get(url)
      PersistentHTTParty.get(url).parsed_response
    end

    def self.get_json(url)
      JSON.parse get(url)
    end
  end
end
