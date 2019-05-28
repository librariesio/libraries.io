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

  describe 'mapping_from_pom_xml' do
    let(:pom) { Ox.parse(File.open("spec/fixtures/proto-google-common-protos-0.1.9.pom").read) }
    let(:parent_pom) { {homepage: 'https://github.com/googleapis/googleapis', licenses: 'unknown'} }
    let(:parent_project) { {name: 'com.google.api.grpc:proto-google-common-parent', groupId: 'com.google.api.grpc', artifactId: 'proto-google-common-parent', versions: []} }
    let(:parsed) { described_class.mapping_from_pom_xml(pom) }

    before do 
      expect(described_class).to receive(:project).and_return(parent_project)
      expect(described_class).to receive(:mapping).with(parent_project).and_return(parent_pom)
    end

    it 'to find license' do
      # parent license should be overwritten by direct pom
      expect(parsed[:licenses]).to eq("Apache-2.0")
    end

    it 'to find description' do
      expect(parsed[:description]).to eq("PROTO library for proto-google-common-protos")
    end

    it 'to find homepage' do
      # homepage value should come from parent pom
      expect(parsed[:homepage]).to eq("https://github.com/googleapis/googleapis")
    end

    it 'to find repository url' do
      expect(parsed[:repository_url]).to eq("https://github.com/googleapis/googleapis-dummy")
    end
  end
end
