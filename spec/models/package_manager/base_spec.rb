require 'rails_helper'

describe PackageManager::Base do
  let(:project) { create(:project, name: 'foo', platform: 'Bower') }

  it 'ignores license changes if admin set it' do
    project_data = {
      licenses: ["MIT"],
      name: project.name,
      description: "project for tests",
      repository_url: "http://libraries.io"
    }

    project.update(
      licenses: 'Apache-2.0',
      normalized_licenses: ['Apache-2.0'],
      license_set_by_admin: true
    )

    # need to use a full package manager since Base class does not implement every method called in save()
    # it helps if the package manager does not have versions or dependencies to avoid those calls
    allow(PackageManager::Bower).to receive(:mapping).and_return project_data
    
    PackageManager::Bower.save(project_data)

    project.reload
    expect(project.licenses).to eql 'Apache-2.0'
  end

  it 'accepts license changes if admin did not set it' do
    project_data = {
      licenses: "MIT",
      name: project.name,
      description: "project for tests",
      repository_url: "http://libraries.io"
    }

    project.update(
      licenses: 'Apache-2.0',
      normalized_licenses: ['Apache-2.0'],
      license_set_by_admin: false
    )

    # need to use a full package manager since Base class does not implement every method called in save()
    # it helps if the package manager does not have versions or dependencies to avoid those calls
    allow(PackageManager::Bower).to receive(:mapping).and_return project_data
    
    PackageManager::Bower.save(project_data)

    project.reload
    expect(project.licenses).to eql 'MIT'
  end
end
