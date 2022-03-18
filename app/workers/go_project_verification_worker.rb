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

    # if this name is found and is considered a module then that should be considered canonical
    unless PackageManager::Go.module?(project.name)
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
