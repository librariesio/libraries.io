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
    let(:parent_pom) { Ox.parse('<project><licenses><license><name>unknown</name></license></licenses><url>https://github.com/googleapis/googleapis</url></project>') }
    let(:parent_project) { {name: 'com.google.api.grpc:proto-google-common-parent', groupId: 'com.google.api.grpc', artifactId: 'proto-google-common-parent', versions: [{number: "1.0", published_at: Time.now.to_s}]} }
    let(:parsed) { described_class.mapping_from_pom_xml(pom) }

    context "with parsed pom" do
      before do
        allow(described_class)
          .to receive(:project)
          .and_return(parent_project)
        allow(described_class)
          .to receive(:get_pom)
          .with('com.google.api.grpc', 'proto-google-common-parent', '0.1.9')
          .and_return(parent_pom)
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
      allow(described_class)
        .to receive(:get_pom)
        .and_return(pom)

      # parent lookup methods should be called 6 times (once here, plus 5 recursions)
      # each call to get the parent will return a pom file also with a parent, which would be an endless loop
      expect(described_class)
        .to receive(:mapping_from_pom_xml)
        .exactly(6)
        .times
        .and_call_original
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
        redirect_pom = Ox.parse('<project><distributionManagement><relocation><groupId>group.id.2</groupId></relocation></distributionManagement></project>')

        allow(described_class).to receive(:get_xml)
          .with(/group_id\/artifact_id\/version/)
          .and_return(redirect_pom)
        allow(described_class).to receive(:get_xml)
          .with(/group\/id\/2\/artifact_id\/version/)
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

  describe '.licenses(xml)' do
    context 'with licences in the XML' do
      it 'returns those licenses' do
        pom = Ox.parse('<project><licenses><license><name>Apache-2.0</name><url>http://www.apache.org/licenses/LICENSE-2.0.txt</url></license></licenses></project>')

        expect(described_class.licenses(pom)).to eq(['Apache-2.0'])
      end
    end

    context 'with licences in the comments' do
      it 'returns those licenses' do
        pom = Ox.parse(
          <<-EOF
            <?xml version="1.0"?>
            <!--
               Licensed to the Apache Software Foundation (ASF) under one or more
               contributor license agreements.  See the NOTICE file distributed with
               this work for additional information regarding copyright ownership.
               The ASF licenses this file to You under the Apache License, Version 2.0
               (the "License"); you may not use this file except in compliance with
               the License.  You may obtain a copy of the License at

                   http://www.apache.org/licenses/LICENSE-2.0

               Unless required by applicable law or agreed to in writing, software
               distributed under the License is distributed on an "AS IS" BASIS,
               WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
               See the License for the specific language governing permissions and
               limitations under the License.
            -->
            <project></project>
          EOF
        )

        expect(described_class.licenses(pom)).to eq(['Apache-2.0'])
      end
    end

    context 'with no licences' do
      it 'returns empty' do
        pom = Ox.parse('<project></project>')
        expect(described_class.licenses(pom)).to be_empty
      end
    end
  end

  describe '.latest_version(project)' do
    context 'with versions in the project' do
      it 'returns the latest version' do
        project = {
          versions: [
            { number: 'previous', published_at: Time.parse('2019-06-04T00:00:00Z') },
            { number: 'latest', published_at: Time.parse('2019-06-04T00:00:01Z') },
          ],
        }
        expect(described_class.latest_version(project)).to eq('latest')
      end
    end

    context 'with no versions in the project' do
      context 'with versions in the DB' do
        it 'falls back to the DB' do
          project = create(:project, name: 'com.tidelift:test', platform: 'Maven')
          create(:version, project: project, number: '1.0.0', published_at: Time.parse('2019-06-04T00:00:00Z'))
          create(:version, project: project, number: '1.0.1', published_at: Time.parse('2019-06-04T00:00:01Z'))

          project = {
            artifactId: 'test',
            groupId: 'com.tidelift',
            name: 'com.tidelift:test',
            versions: [],
          }
          expect(described_class.latest_version(project)).to eq('1.0.1')
        end
      end

      context 'with no versions in the DB' do
        it 'returns nothing' do
          project = {
            versions: [],
          }
          expect(described_class.latest_version(project)).to be_nil
        end
      end
    end
  end
end
