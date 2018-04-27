module PackageManager
  class Opam < Base
    HAS_VERSIONS = false
    HAS_DEPENDENCIES = false
    BIBLIOTHECARY_SUPPORT = false
    BIBLIOTHECARY_PLANNED = true
    URL = 'https://opam.ocaml.org'
    COLOR = '#3be133'

    def self.project_names
      get_html("https://opam.ocaml.org/packages/").css('tbody tr').map{|tr| tr.css('a').first.try(:text)}
    end

    def self.project(name)
      {
          name: name,
          page: get_html("https://opam.ocaml.org/packages/#{name}/")
      }
    end

    def self.mapping(project)
      {
          name: project[:name],
          keywords_array: extract_keywords(project[:page]),
          description: extract_description(project[:page]),
          licenses: extract_licenses(project[:page]),
          homepage: extract_homepage(project[:page]),
          repository_url: extract_repository_url(project[:page])
      }
    end

    def self.extract_keywords(page)
      list_str = find_attribute(page, 'Tags')
      list_str ? generate_list(list_str) : []
    end

    def self.extract_description(page)
      page.css('.well h4').try(:text)
    end

    def self.extract_licenses(page)
      find_attribute(page, 'License')
    end

    def self.extract_homepage(page)
      find_attribute(page, 'Homepage')
    end

    def self.extract_repository_url(page)
      repository_url = find_attribute(page, 'Issue Tracker')
      repository_url.chomp('/issues') if repository_url
    end

    def self.find_attribute(page, name)
      tr = page.css('.table tr').select { |t| t.css('th').text == name }.first
      tr.css('td').text if tr
    end

    def self.generate_list(list_str)
      list_str.split(/,\s|\sand\s/)
    end

    def self.formatted_name
      'opam'
    end

    def self.package_link(project, _version = nil)
      "https://opam.ocaml.org/packages/#{project}/" + (_version ? "#{project}.#{_version}" : "")
    end

    def self.install_instructions(project, version = nil)
      "opam install #{project}" + (version ? ".#{version}" : "")
    end
  end
end