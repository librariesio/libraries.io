class VersionsMailer < ApplicationMailer
  def new_version(user, project, version)
    @user = user
    @version = version
    @project = project
    @repos = @project.subscribed_repos(@user)

    return if user.email.empty?

    mail to: user.email, subject: "New release of #{@project} (#{version.number}) on #{@project.platform_name}"
  end
end
