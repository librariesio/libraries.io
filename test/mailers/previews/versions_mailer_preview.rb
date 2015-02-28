# Preview all emails at http://localhost:3000/rails/mailers/versions_mailer
class VersionsMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/versions_mailer/new_version
  def new_version
    VersionsMailer.new_version(User.first, Version.last)
  end

end
