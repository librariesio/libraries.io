# frozen_string_literal: true
# Preview all emails at http://localhost:3000/rails/mailers/versions_mailer
class VersionsMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/versions_mailer/new_version
  def new_version
    user = User.new({email: 'foo@bar.com', optin: false})
    version = Version.first
    VersionsMailer.new_version(user, version.project, version)
  end
end
