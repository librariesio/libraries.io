require 'rails_helper'

describe PackageManager::Conda do
  let(:project) { create(:project, name: 'foo', platform: described_class.name) }

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

  describe '#versions' do
    it 'parses the conda timestamp as publish_date' do
      timestamp = 1568903457
      expected_date = Time.at(timestamp)
      unmapped_project = {
        "version"=>"1.0.0",
        "timestamp"=>timestamp
      }

      expect(described_class.versions(unmapped_project, "fakename").first).to eq({number: "1.0.0", published_at: expected_date})
    end

    it 'can handle a 0 timestamp from conda' do
      timestamp = 0
      expected_date = Time.at(timestamp)
      unmapped_project = {
        "version"=>"1.0.0",
        "timestamp"=>timestamp
      }

      expect(described_class.versions(unmapped_project, "fakename").first).to eq({number: "1.0.0", published_at: expected_date})
    end
  end
end
