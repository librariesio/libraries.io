# frozen_string_literal: true
module PackageManager
  class Carthage < Base
    HAS_VERSIONS = false
    HAS_DEPENDENCIES = false
    BIBLIOTHECARY_SUPPORT = true
    URL = 'https://github.com/Carthage/Carthage'
    COLOR = '#ffac45'

    def self.project_names
      Manifest.platform('Carthage').includes(:repository_dependencies).map{|m| m.repository_dependencies.map(&:project_name).compact.map(&:downcase)}.flatten.uniq
    end

    def self.project(name)
      if name.match(/^([-\w]+)\/([-.\w]+)$/)
        begin
          repo = AuthToken.client.repo(name, accept: 'application/vnd.github.drax-preview+json,application/vnd.github.mercy-preview+json')
          return repo.to_hash
        rescue
          return nil
        end
      elsif name_with_owner = GitlabURLParser.parse(name)
        begin
          repo = AuthToken.client.repo(name_with_owner, accept: 'application/vnd.github.drax-preview+json,application/vnd.github.mercy-preview+json')
          return repo.to_hash
        rescue
          return nil
        end
      elsif name.match(/^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$/)
        begin
          response = request(name)
          if response.status == 200
            {
              full_name: name.sub(/^https?\:\/\//, ''),
              homepage: name
            }
          end
        rescue
          nil
        end
      end
    end

    def self.mapping(project)
      {
        :name => project[:full_name],
        :description => project[:description],
        :homepage => project[:homepage],
        :keywords_array => project[:topics],
        :licenses => (project.fetch(:license, {}) || {})[:key],
        :repository_url => project[:html_url]
      }
    end
  end
end
