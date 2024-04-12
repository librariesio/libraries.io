# frozen_string_literal: true

# This worker is meant to verify if this package name is correct and found on the resources used as the
# Go platform's source of truth. If a project name is not found, then go ahead and delete the Project from libraries.
# If it is found, but is not the canonical name that should be used, then attempt to find the correct name and
# use that Project only without creating any new Projects with similar but incorrect names.
class GoProjectVerificationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :small

  def perform(name)
    project = Project.find_by(platform: "Go", name: name)

    # check to see if the module is found on pkg.go.dev and if it isn't then go ahead and delete this name
    return project.destroy unless PackageManager::Go.valid_project?(project.name)

    # if this name is found and is considered a module then we can determine the canonical name
    if PackageManager::Go.module?(project.name)
      canonical_name = PackageManager::Go.canonical_module_name(project.name)

      # if we can't get a canonical name then bail out of here and we'll have to investigate further
      return if canonical_name.blank?

      # if the name for the project doesn't match the canonical name then we can remove it
      PackageManager::Go.update(canonical_name) unless Project.where(platform: "Go", name: canonical_name).exists?

      if project.name != canonical_name
        if canonical_name.downcase == project.name.downcase
          StructuredLog.capture(
            "GO_PROJECT_VERIFICATION_DESTROY_PROJECT",
            {
              project_name: project.name,
              canonical_name: canonical_name,
            }
          )
          project.destroy
        else
          StructuredLog.capture(
            "GO_PROJECT_VERIFICATION_REMOVE_PROJECT",
            {
              project_name: project.name,
              canonical_name: canonical_name,
            }
          )
          project.update(status: "Removed")
        end
      end
    else
      # not a module
      # figure out what the correct module name is
      module_name = non_module_name(name)

      # If we have a different name come back then run an update on the new name if we don't already have a Project for it
      # and delete the Project with the name that was passed in.
      #
      # The goal is to have only one remaining Project for the name passed in here to avoid having multiple projects
      # with different cased names for the same package.
      if name != module_name
        PackageManager::Go.update(module_name) unless module_name.nil? || Project.where(platform: "Go", name: module_name).exists?

        StructuredLog.capture(
          "GO_PROJECT_VERIFICATION_DESTROY_NON_MODULE_PROJECT",
          {
            project_name: project.name,
            non_module_name: module_name,
          }
        )

        project.destroy
      end
    end
  end

  private

  # attempt to figure out the correct module name by querying the Go proxy server and reading the generated mod file
  # if the proxy sends back the same cased name that we sent, then it will likely do that for all the different casings
  # in that case downcase the name and use that as the canonical name for this package
  def non_module_name(name)
    proxy_name = PackageManager::Go.canonical_module_name(name)

    proxy_name = proxy_name.downcase if proxy_name == name
    proxy_name
  end
end
