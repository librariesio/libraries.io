namespace :one_off do
  task get_ruby_deps: :environment do
    Project.platform('Rubygems').find_each do |proj|
      name = proj.name
      version = proj.latest_version
      deps = Repositories::Rubygems.dependencies(name, version.number)
      next unless deps.any? && version.dependencies.empty?
      deps.each do |dep|
        unless version.dependencies.find_by_project_name dep[:project_name]
          named_project = Project.platform('Rubygems').where('lower(name) = ?', dep[:project_name].downcase).first.try(:id)
          version.dependencies.create(dep.merge(project_id: named_project))
        end
      end
    end
  end
end
