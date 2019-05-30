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
    let(:parent_pom) { {homepage: 'https://github.com/googleapis/googleapis', licenses: 'unknown'} }
    let(:parent_project) { {name: 'com.google.api.grpc:proto-google-common-parent', groupId: 'com.google.api.grpc', artifactId: 'proto-google-common-parent', versions: [{number: "1.0", published_at: Time.now.to_s}]} }
    let(:parsed) { described_class.mapping_from_pom_xml(pom) }

    context "with parsed pom" do
      before do 
        expect(described_class).to receive(:project).and_return(parent_project)
        expect(described_class).to receive(:mapping).with(parent_project, 1).and_return(parent_pom)
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
  
    it 'to stop calling parent poms at maximum depth' do
      # parent lookup methods should be called 5 times
      # each call to get the parent will return a pom file also with a parent, which would be an endless loop
      expect(described_class).to receive(:project).exactly(5).times.and_return(parent_project)
      expect(described_class).to receive(:get_xml).exactly(5).times.and_return(pom)
      expect(described_class).to receive(:mapping).exactly(5).times.and_call_original
      described_class.mapping_from_pom_xml(pom)
    end
  end

  describe '.get_pom(group_id, artifact_id, version)' do
    context 'with no relocation' do
      it 'returns the expected data' do
        simple_pom = Ox.parse('<project></project>')

        allow(described_class).to receive(:get_xml)
          .with(/group_id\/artifact_id\/version/)
          .and_return(simple_pom)

        expect(described_class.get_pom('group_id', 'artifact_id', 'version'))
          .to eq(simple_pom)
      end
    end

    context 'with a simple relocation' do
      it 'returns the expected data' do
        simple_pom = Ox.parse('<project></project>')
        redirect_pom = Ox.parse('<project><distributionManagement><relocation><groupId>group_id_2</groupId></relocation></distributionManagement></project>')

        allow(described_class).to receive(:get_xml)
          .with(/group_id\/artifact_id\/version/)
          .and_return(redirect_pom)
        allow(described_class).to receive(:get_xml)
          .with(/group_id_2\/artifact_id\/version/)
          .and_return(simple_pom)

        expect(described_class.get_pom('group_id', 'artifact_id', 'version'))
          .to eq(simple_pom)
      end
    end

    context 'with a broken relocation' do
      it 'returns the expected data' do
        redirect_pom = Ox.parse('<project><distributionManagement><relocation><groupId>group_id_2</groupId></relocation></distributionManagement></project>')

        allow(described_class).to receive(:get_xml)
          .with(/group_id\/artifact_id\/version/)
          .and_return(redirect_pom)
        allow(described_class).to receive(:get_xml)
          .with(/group_id_2\/artifact_id\/version/)
          .and_raise(Faraday::Error)

        expect(described_class.get_pom('group_id', 'artifact_id', 'version'))
          .to eq(redirect_pom)
      end
    end

    context 'with an infinite relocation loop' do
      it 'terminates' do
        redirect_pom = Ox.parse('<project><distributionManagement><relocation><groupId>group_id_2</groupId></relocation></distributionManagement></project>')
        redirect_pom_2 = Ox.parse('<project><distributionManagement><relocation><groupId>group_id</groupId></relocation></distributionManagement></project>')

        allow(described_class).to receive(:get_xml)
          .with(/group_id\/artifact_id\/version/)
          .and_return(redirect_pom)
        allow(described_class).to receive(:get_xml)
          .with(/group_id_2\/artifact_id\/version/)
          .and_return(redirect_pom_2)

        expect(described_class.get_pom('group_id', 'artifact_id', 'version'))
          .to eq(redirect_pom_2)
      end
    end
  end
end
