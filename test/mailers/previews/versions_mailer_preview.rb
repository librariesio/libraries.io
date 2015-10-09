# Preview all emails at http://localhost:3000/rails/mailers/versions_mailer
class VersionsMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/versions_mailer/new_version
  def new_version
    version = Version.last
    VersionsMailer.new_version(User.first, version.project, version)
  end

  # Preview this email at http://localhost:3000/rails/mailers/versions_mailer/new_tag
  def new_tag
    tag = GithubTag.joins(:github_repository => :projects).first
    repo = tag.github_repository
    project = repo.projects.first
    VersionsMailer.new_version(User.first, project, tag)
  end
end
