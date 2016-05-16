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
end
