class Readme < ApplicationRecord
  belongs_to :github_repository
  validates_presence_of :html_body, :github_repository

  after_validation :reformat

  after_commit :check_unmaintained

  def to_s
    html_body
  end

  def plain_text
    @plain_text ||= Nokogiri::HTML(html_body).text
  end

  def check_unmaintained
    return unless unmaintained?
    github_repository.update_attribute(:status, 'Unmaintained')
    github_repository.projects.each do |project|
      project.update_attribute(:status, 'Unmaintained')
    end
  end

  def unmaintained?
    html_body.downcase.gsub("\n", '').include?('unmaintained.tech/badge.svg')
  end

  def reformat
    doc = Nokogiri::HTML(html_body)
    doc.xpath('//a').each do |d|
      rel_url = d.get_attribute('href')
      begin
        if rel_url.present? && !rel_url.match(/^#/) && URI.parse(rel_url)
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
    text = Highscore::Content.new(Nokogiri::HTML(html_body).text, Readme.badlist)
    text.configure { set :ignore_case, true }
    text.keywords.top(5).select{|k| k.weight > 9 && k.text.length < 20 }.map(&:text)
  end

  def self.badlist
    @blacklist ||= init_blacklist
  end

  def self.init_blacklist
    badlist_words = %w{library bsd3 mit gpl which software create value license
      public more know what how between name files class also true false type
      default would have install com code like change project href script scripts
      same foo from char function var method string nim agpl case def let func
      return key try txt chr set nil int} +
    Highscore::Blacklist.load_default_file.words +
    Languages::Language.all.map{|l| l.name.downcase } +
    Download.platforms.map{|p| p.to_s.demodulize.downcase }
    Highscore::Blacklist.load badlist_words
  end
end
