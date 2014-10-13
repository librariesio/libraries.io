class Repositories
  class Base
    def self.save(project)
      mapped_project = mapping(project)
      project = Project.find_or_create_by({:name => mapped_project[:name], :platform => self.name.demodulize})
      project.update_attributes(mapped_project.except(:name))
      project
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
