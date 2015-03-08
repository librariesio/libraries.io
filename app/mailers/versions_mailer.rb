class VersionsMailer < ApplicationMailer
  def new_version(user, project, version)
    @user = user
    @version = version
    @project = project

    mail to: user.email, subject: "New release of #{@project} (#{version.number}) on #{@project.platform}"
  end
end
