require 'rails_helper'

describe PackageManager::Maven do
  it 'has formatted name of "Maven"' do
    expect(described_class.formatted_name).to eq('Maven')
  end

  describe '#package_link' do
    let(:project) { create(:project, name: 'com.github.jparkie:pdd', platform: described_class.name) }

    it 'returns a link to project website' do
      expect(described_class.package_link(project)).to eq("http://search.maven.org/#search%7Cgav%7C1%7Cg%3A%22com.github.jparkie%22%20AND%20a%3A%22pdd%22")
    end

    it 'handles version' do
      expect(described_class.package_link(project, '2.0.0')).to eq("http://search.maven.org/#artifactdetails%7Ccom.github.jparkie%7Cpdd%7C2.0.0%7Cjar")
    end
  end
end
