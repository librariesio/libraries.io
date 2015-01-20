class GithubRepository < ActiveRecord::Base
  # validations (presense and uniqueness)

  belongs_to :project

  def to_s
    full_name
  end

  def owner_name
    full_name.split('/')[0]
  end

  def project_name
    full_name.split('/')[1]
  end

  def pages_url
    "http://#{owner_name}.github.io/#{project_name}"
  end

  def wiki_url
    "#{url}/wiki"
  end

  def url
    "https://github.com/#{full_name}"
  end

  def avatar_url(size = 60)
    "https://avatars.githubusercontent.com/u/#{owner_id}?size=#{size}"
  end
end
