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

  describe '#check_status_url' do
    let(:project) { create(:project, name: 'javax.faces:javax.faces-api', platform: described_class.name) }

    it 'returns link to maven central folder' do
      expect(described_class.check_status_url(project)).to eq("https://repo1.maven.org/maven2/javax/faces/javax.faces-api")
    end
  end

  describe '#download_url' do
    let(:project) { create(:project, name: 'javax.faces:javax.faces-api', platform: described_class.name) }

    it 'returns link to maven central jar file' do
      expect(described_class.download_url(project.name, '2.3')).to eq("https://repo1.maven.org/maven2/javax/faces/javax.faces-api/2.3/javax.faces-api-2.3.jar")
    end
  end

  describe 'mapping_from_pom_xml' do
    let(:pom) { Ox.parse(File.open("spec/fixtures/proto-google-common-protos-0.1.9.pom").read) }
    let(:parsed) { described_class.mapping_from_pom_xml(pom) }

    it 'to find license' do
      expect(parsed[:licenses]).to eq("Apache-2.0")
    end

    it 'to find description' do
      expect(parsed[:description]).to eq("PROTO library for proto-google-common-protos")
    end

    it 'to find homepage' do
      expect(parsed[:homepage]).to eq("https://github.com/googleapis/googleapis")
    end

    it 'to find repository url' do
      expect(parsed[:repository_url]).to eq("https://github.com/googleapis/googleapis-dummy")
    end
  end
end
