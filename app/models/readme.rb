class Readme < ActiveRecord::Base
  belongs_to :github_repository
  validates_presence_of :html_body

  before_validation :reformat

  def to_s
    html_body
  end

  def reformat
    doc = Nokogiri::HTML(html_body)
    doc.xpath('//a').each do |d|
      rel_url = d.get_attribute('href')
      d.set_attribute('href', URI.join(github_repository.blob_url, rel_url))
    end
    self.html_body = doc.to_s
  end
end
