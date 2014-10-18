class Repositories
  class Base
    def self.save(project)
      mapped_project = mapping(project)
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
      project_names.each{|name| update(name) }
    end
  end
end
