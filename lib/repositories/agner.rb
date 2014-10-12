class Repositories
  class Agner
    PLATFORM = 'Agner'

    def self.project_names
      Octokit.auto_paginate = true
      repos = Octokit.org_repos('agner')
      repos.map(&:name).select{|name| name.match(/\.agner$/)}.map{|name| name.match(/(.+?)\.agner$/)[1] }
    end

    def self.project(name)
      config = Octokit.contents("agner/#{name}.agner", :path => 'agner.config').content
      contents = Base64.decode64(config)
      package = {}
      contents.split( /\r?\n/ ).each do |line|
        package.merge! ErlangParser.new.erl_to_ruby(line.match(/(.+?)[\.]?$/)[1])
      end
      package
    end

    def self.keys
      [:name, :description, :url, :homepage, :rebar_compatible, :applications, :authors, :license]
    end

    def self.mapping(project)
      {
        :name => project[:name],
        :description => project[:description],
        :homepage => project[:homepage]
      }
    end

    def self.save(project)
      mapped_project = mapping(project)
      project = Project.find_or_create_by({:name => mapped_project[:name], :platform => PLATFORM})
      project.update_attributes(mapped_project.slice(:description, :homepage))
      project
    end

    def self.update(name)
      save(project(name))
    end

    # TODO repo, license, authors
  end
end
