# frozen_string_literal: true
require 'rails_helper'

describe PackageManager::Conda do
  let(:project) { create(:project, name: 'foo', platform: described_class.db_platform) }

  it 'has formatted name of "conda"' do
    expect(described_class.formatted_name).to eq('conda')
  end

  describe '#package_link' do
    it 'returns a link to project website' do
      expect(described_class.package_link(project)).to eq("https://anaconda.org/anaconda/foo")
    end

    it 'ignores version' do
      expect(described_class.package_link(project, '2.0.0')).to eq("https://anaconda.org/anaconda/foo")
    end
  end

  describe '#install_instructions' do
    it 'returns a command to install the project' do
      expect(described_class.install_instructions(project)).to eq("conda install -c anaconda foo")
    end
  end


  describe 'finds repository urls' do
    it 'updates repository_url' do
      allow(described_class)
        .to receive(:project)
        .and_return({
          "name" => project.name, 
          "versions" => [],
          "repository_url" => "https://this-is-my-repo-url"
        })
      described_class.update(project.name)
      expect(project.reload.repository_url).to eq("https://this-is-my-repo-url")
    end

    it 'updating doesnt ovewrite repository_url if previously set by admin' do
      original_repository_url = project.repository_url
      project.update_column(:repository_url_set_by_admin, true)
      allow(described_class)
        .to receive(:project)
        .and_return({
          "name" => project.name, 
          "versions" => [],
          "repository_url" => "https://this-is-the-wrong-url"
        })
      described_class.update(project.name)
      
      expect(project.reload.repository_url).to eq(original_repository_url)
    end
  end
end
