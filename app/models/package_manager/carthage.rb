# frozen_string_literal: true

module PackageManager
  class Carthage < Base
    HAS_VERSIONS = false
    HAS_DEPENDENCIES = false
    BIBLIOTHECARY_SUPPORT = true
    URL = "https://github.com/Carthage/Carthage"
    COLOR = "#ffac45"

    def self.project_names
      Project.platform("Carthage")
        .joins(:repository)
        .includes(:repository)
        .map(&:repository)
        .flat_map do |r|
          r.projects_dependencies.map(&:project_name).compact.map(&:downcase)
        end
        .uniq
    end

    def self.project(name)
      if name.match(/^([-\w]+)\/([-.\w]+)$/)
        begin
          repo = AuthToken.client.repo(name, accept: "application/vnd.github.drax-preview+json,application/vnd.github.mercy-preview+json")
          repo.to_hash
        rescue StandardError
          nil
        end
      elsif (name_with_owner = GitlabURLParser.parse(name))
        begin
          repo = AuthToken.client.repo(name_with_owner, accept: "application/vnd.github.drax-preview+json,application/vnd.github.mercy-preview+json")
          repo.to_hash
        rescue StandardError
          nil
        end
      elsif name.match(/^(https?:\/\/)?([\da-z.-]+)\.([a-z.]{2,6})([\/\w .-]*)*\/?$/)
        begin
          response = request(name)
          if response.status == 200
            {
              full_name: name.sub(/^https?:\/\//, ""),
              homepage: name,
            }
          end
        rescue StandardError
          nil
        end
      end
    end

    def self.mapping(raw_project)
      MappingBuilder.build_hash(
        name: raw_project[:full_name],
        description: raw_project[:description],
        homepage: raw_project[:homepage],
        keywords_array: raw_project[:topics],
        licenses: (raw_project.fetch(:license, {}) || {})[:key],
        repository_url: raw_project[:html_url]
      )
    end
  end
end
