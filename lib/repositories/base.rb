class Repositories
  class Base
    def self.save(project)
      mapped_project = mapping(project)
      return false unless mapped_project
      puts "Saving #{mapped_project[:name]}"
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
        p e
        raise e
      end
    end

    def self.import
      name = self.name.demodulize
      puts "Importing #{name}"
      before = Time.now.utc
      Parallel.each(project_names){|name| update(name)}
      ActiveRecord::Base.connection.reconnect!
      count = Project.platform(name).where('created_at > ?', before).count
      puts "Imported #{count} new #{name} projects"
    end

    def self.get(url)
      HTTParty.get(url).parsed_response
    end

    def self.get_json(url)
      HTTParty.get(url, headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }).parsed_response
    end
  end
end
