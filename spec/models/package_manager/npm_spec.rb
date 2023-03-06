# frozen_string_literal: true
require 'rails_helper'

describe PackageManager::NPM do
  let(:project) { create(:project, name: 'foo', platform: described_class.formatted_name) }

  it 'has formatted name of "npm"' do
    expect(described_class.formatted_name).to eq('npm')
  end

  describe '#package_link' do
    it 'returns a link to project website' do
      expect(described_class.package_link(project)).to eq("https://www.npmjs.com/package/foo")
    end

    it 'ignores version' do
      expect(described_class.package_link(project, '2.0.0')).to eq("https://www.npmjs.com/package/foo")
    end
  end

  describe 'download_url' do
    it 'returns a link to project tarball' do
      expect(described_class.download_url(project, '1.0.0')).to eq("https://registry.npmjs.org/foo/-/foo-1.0.0.tgz")
    end
  end

  describe '#install_instructions' do
    it 'returns a command to install the project' do
      expect(described_class.install_instructions(project)).to eq("npm install foo")
    end

    it 'handles version' do
      expect(described_class.install_instructions(project, '2.0.0')).to eq("npm install foo@2.0.0")
    end
  end

  describe '#deprecation_info' do
    it "returns not-deprecated if any version isn't deprecated" do
      expect(PackageManager::NPM).to receive(:project).with('foo').and_return({
        "versions" => {
          "0.0.1" => { "deprecated" => "This package is deprecated" },
          "0.0.2" => { "deprecated" => "This package is deprecated" },
          "0.0.3" => {},
        }
      })

      expect(described_class.deprecation_info('foo')).to eq({is_deprecated: false, message: nil})
    end

    it "returns deprecated if all versions are deprecated" do
      expect(PackageManager::NPM).to receive(:project).with('foo').and_return({
        "versions" => {
          "0.0.1" => { "deprecated" => "This package is deprecated" },
          "0.0.2" => { "deprecated" => "This package is deprecated" },
          "0.0.3" => { "deprecated" => "This package is deprecated" },
        }
      })

      expect(described_class.deprecation_info('foo')).to eq({is_deprecated: true, message: "This package is deprecated"})
    end
  end
end
