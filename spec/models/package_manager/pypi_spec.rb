require 'rails_helper'

describe PackageManager::Pypi do
  let(:project) { create(:project, name: 'foo', platform: described_class.name) }

  it 'has formatted name of "PyPI"' do
    expect(described_class.formatted_name).to eq('PyPI')
  end

  describe '#package_link' do
    it 'returns a link to project website' do
      expect(described_class.package_link(project)).to eq("https://pypi.org/project/foo/")
    end

    it 'handles version' do
      expect(described_class.package_link(project, '2.0.0')).to eq("https://pypi.org/project/foo/2.0.0")
    end
  end

  describe '#install_instructions' do
    it 'returns a command to install the project' do
      expect(described_class.install_instructions(project)).to eq("pip install foo")
    end

    it 'handles version' do
      expect(described_class.install_instructions(project, '2.0.0')).to eq("pip install foo==2.0.0")
    end
  end

  describe 'handles licenses' do
    it 'from classifiers' do
      requests = JSON.parse(File.open("spec/fixtures/pypi-specified-license.json").read)
      expect(described_class.mapping(requests)[:licenses]).to eq("Apache 2.0")
    end

    it 'from classifiers' do
      bandit = JSON.parse(File.open("spec/fixtures/pypi-classified-license-only.json").read)
      expect(described_class.mapping(bandit)[:licenses]).to eq("Apache Software License")
    end
  end
end
