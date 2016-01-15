class Readme < ActiveRecord::Base
  belongs_to :github_repository#, touch: true
  validates_presence_of :html_body, :github_repository

  after_validation :reformat

  after_commit :check_unmaintained

  def to_s
    html_body
  end

  def plain_text
    @plain_text ||= Nokogiri::HTML(html_body).text
  end

  def mit_licensed?
    plain_text.downcase.gsub("\n", '').include? mit_license_text.downcase.gsub("\n", '')
  end

  def mit_license_text
    "Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE."
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
end
