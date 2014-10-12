class Repositories
  class Agner < Base
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

    def self.mapping(project)
      {
        :name => project[:name],
        :description => project[:description],
        :homepage => project[:homepage]
      }
    end

    # TODO repo, license, authors
  end
end
