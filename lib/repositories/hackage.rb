class Repositories
  class Hackage < Base
    HAS_VERSIONS = true
    HAS_DEPENDENCIES = true
    URL = 'http://hackage.haskell.org'

    def self.project_names
      get_json("http://hackage.haskell.org/packages/").map{ |h| h['packageName'] }
    end

    def self.project(name)
      {
        name: name,
        page: Nokogiri::HTML(get("http://hackage.haskell.org/package/#{name}"))
      }
    end

    def self.mapping(project)
      {
        name: project[:name],
        keywords: project[:page].css('#content div:first a')[1..-1].map(&:text).join(','),
        description: description(project[:page]),
        licenses: find_attribute(project[:page], 'License'),
        homepage: find_attribute(project[:page], 'Home page'),
        repository_url: repository_url(find_attribute(project[:page], 'Source repository'))
      }
    end

    def self.versions(project)
      versions = find_attribute(project[:page], 'Versions')
      versions = find_attribute(project[:page], 'Version') if versions.nil?
      versions.split(',').map(&:strip).map do |v|
        {
          :number => v
        }
      end
    end

    def self.find_attribute(page, name)
      tr = page.css('#content tr').select { |t| t.css('th').text == name }.first
      tr.css('td').text if tr
    end

    def self.description(page)
      contents = page.css('#content p, #content hr' ).map(&:text)
      index = contents.index ''
      contents[0..(index - 1)].join("\n\n")
    end

    def self.repository_url(text)
      return nil unless text.present?
      match = text.match(/github.com\/(.+?)\.git/)
      return nil unless match
      "https://github.com/#{match[1]}"
    end
  end
end
