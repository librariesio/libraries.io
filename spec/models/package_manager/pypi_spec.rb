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

  describe 'finds repository urls' do
    it 'from the rarely-populated repository url' do
      requests = JSON.parse(File.open("spec/fixtures/pypi-with-repository.json").read)
      expect(described_class.mapping(requests)[:repository_url]).to eq("https://github.com/python-attrs/attrs")
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

  describe 'project_find_names' do
    it 'suggests underscore version of name' do
      suggested_find_names = described_class.project_find_names('test-hyphen')
      expect(suggested_find_names).to include('test_hyphen', 'test-hyphen')
    end

    it 'suggests hyphen version of name' do
      suggested_find_names = described_class.project_find_names('test_underscore')
      expect(suggested_find_names).to include('test-underscore', 'test_underscore')
    end
  end

  describe '#deprecation_info' do
    it "returns not-deprecated if last version isn't deprecated" do
      expect(PackageManager::Pypi).to receive(:project).with('foo').and_return({
        "releases" => {
            "0.0.1" => [{}],
            "0.0.2" => [{"yanked" => true, "yanked_reason" => "This package is deprecated"}],
            "0.0.3" => [{}]
        }
      })

      expect(described_class.deprecation_info('foo')).to eq({is_deprecated: false, message: nil})
    end

    it "returns deprecated if last version is deprecated" do
      expect(PackageManager::Pypi).to receive(:project).with('foo').and_return({
        "releases" => {
            "0.0.1" => [{}],
            "0.0.2" => [{"yanked" => true, "yanked_reason" => "This package is deprecated"}],
            "0.0.3" => [{"yanked" => true, "yanked_reason" => "This package is deprecated"}]
        }
      })

      expect(described_class.deprecation_info('foo')).to eq({is_deprecated: true, message: "This package is deprecated"})
    end
  end
end
