module PackageManager
  class PreCommit < Base
    HAS_VERSIONS = false
    HAS_DEPENDENCIES = false
    BIBLIOTHECARY_SUPPORT = true
    URL = "https://pre-commit.com/"
    COLOR = "#3572A5"

    def self.project_names
      get("https://pre-commit.com/all-hooks.json")
        .values
        .flatten
        .map { |hook| hook["id"] }
    end

    def self.project(name)
      repo = get("https://pre-commit.com/all-hooks.json")
        .find { |repo,hooks| hooks.any? { |hook| hook["id"] == name } }

      hook = repo[1]
        .find { |hook| hook["id"] == name }

      {
        repo: repo[0],
        id: hook["id"],
        language: hook["language"],
        description: hook.fetch("description", ""),
      }
    end

    def self.mapping(project)
      {
        name: project[:id],
        description: project[:description],
        repository_url: project[:repo],
      }
    end

    def self.formatted_name
      "pre-commit"
    end
  end
end
