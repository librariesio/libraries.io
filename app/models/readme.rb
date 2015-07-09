class Readme < ActiveRecord::Base
  belongs_to :github_repository
  validates_presence_of :html_body, :github_repository

  after_validation :reformat

  def to_s
    html_body
  end

  def reformat
    doc = Nokogiri::HTML(html_body)
    doc.xpath('//a').each do |d|
      rel_url = d.get_attribute('href')
      begin
        if rel_url.present? && URI.parse(rel_url)
          d.set_attribute('href', URI.join(github_repository.blob_url, rel_url))
        end
      rescue NoMethodError, URI::InvalidURIError, URI::InvalidComponentError
      end
    end
    doc.xpath('//img').each do |d|
      rel_url = d.get_attribute('src')

      begin
        if rel_url.present? && URI.parse(rel_url)
          d.set_attribute('src', URI.join(github_repository.raw_url, rel_url))
        end
      rescue NoMethodError, URI::InvalidURIError, URI::InvalidComponentError
      end
    end
    self.html_body = doc.to_s
  end

  def keywords
    text = Highscore::Content.new(Nokogiri::HTML(html_body).text, blacklist)
    text.configure { set :ignore_case, true }
    text.keywords.top(5).select{|k| k.weight > 7 && k.text.length < 20 }.map(&:text)
  end

  def blacklist
    blacklist_words = %w{library software create value href script scripts same foo from char function var method string nim} +
    Highscore::Blacklist.load_default_file.words +
    Languages::Language.all.map{|l| l.name.downcase } +
    Download.platforms.map{|p| p.to_s.demodulize.downcase }
    Highscore::Blacklist.load blacklist_words
  end
end
