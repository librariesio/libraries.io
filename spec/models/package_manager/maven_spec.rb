# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Maven do
  it 'has formatted name of "Maven"' do
    expect(described_class.formatted_name).to eq("Maven")
  end

  describe "#package_link" do
    let(:project) { create(:project, name: "com.github.jparkie:pdd", platform: described_class.formatted_name) }

    it "returns a link to project website" do
      expect(described_class.package_link(project)).to eq("https://repo1.maven.org/maven2/com/github/jparkie/pdd")
    end

    it "handles version" do
      expect(described_class.package_link(project, "2.0.0")).to eq("https://repo1.maven.org/maven2/com/github/jparkie/pdd/2.0.0/pdd-2.0.0.jar")
    end

    context "with maven central provider" do
      let!(:version) { create(:version, project: project, repository_sources: ["Maven"], number: "2.0.0") }

      it "returns a link to project website" do
        expect(described_class.package_link(project)).to eq("https://repo1.maven.org/maven2/com/github/jparkie/pdd")
      end

      it "handles version" do
        expect(described_class.package_link(project, "2.0.0")).to eq("https://repo1.maven.org/maven2/com/github/jparkie/pdd/2.0.0/pdd-2.0.0.jar")
      end
    end

    context "with spring-lib-releases provider" do
      let!(:version) { create(:version, project: project, repository_sources: [PackageManager::Maven::SpringLibs::REPOSITORY_SOURCE_NAME], number: "2.0.0") }

      it "handles version" do
        expect(described_class.package_link(project, "2.0.0")).to eq("https://repo.spring.io/libs-release-local/com/github/jparkie/pdd/2.0.0/pdd-2.0.0.jar")
      end
    end

    context "with atlassian provider" do
      let!(:version) { create(:version, project: project, repository_sources: [PackageManager::Maven::Atlassian::REPOSITORY_SOURCE_NAME], number: "2.0.0") }

      it "handles version" do
        expect(described_class.package_link(project, "2.0.0")).to eq("https://packages.atlassian.com/maven-central-local/com/github/jparkie/pdd/2.0.0/pdd-2.0.0.jar")
      end
    end

    context "with hortonworks provider" do
      let!(:version) { create(:version, project: project, repository_sources: [PackageManager::Maven::Hortonworks::REPOSITORY_SOURCE_NAME], number: "2.0.0") }

      it "handles version" do
        expect(described_class.package_link(project, "2.0.0")).to eq("https://repo.hortonworks.com/content/groups/releases/com/github/jparkie/pdd/2.0.0/pdd-2.0.0.jar")
      end
    end

    context "with jboss provider" do
      let!(:version) { create(:version, project: project, repository_sources: [PackageManager::Maven::Jboss::REPOSITORY_SOURCE_NAME], number: "2.0.0") }

      it "handles version" do
        expect(described_class.package_link(project, "2.0.0")).to eq("https://repository.jboss.org/nexus/content/repositories/releases/com/github/jparkie/pdd/2.0.0/pdd-2.0.0.jar")
      end
    end

    context "with jboss_ea" do
      let!(:version) { create(:version, project: project, repository_sources: [PackageManager::Maven::JbossEa::REPOSITORY_SOURCE_NAME], number: "2.0.0") }

      it "handles version" do
        expect(described_class.package_link(project, "2.0.0")).to eq("https://repository.jboss.org/nexus/content/repositories/ea/com/github/jparkie/pdd/2.0.0/pdd-2.0.0.jar")
      end
    end

    context "with multiple providers" do
      let!(:version) { create(:version, project: project, repository_sources: ["Maven", PackageManager::Maven::SpringLibs::REPOSITORY_SOURCE_NAME], number: "2.0.0") }

      it "handles version" do
        expect(described_class.package_link(project, "2.0.0")).to eq("https://repo1.maven.org/maven2/com/github/jparkie/pdd/2.0.0/pdd-2.0.0.jar")
      end
    end
  end

  describe "#check_status_url" do
    let(:project) { create(:project, name: "javax.faces:javax.faces-api", platform: described_class.formatted_name) }

    it "returns link to maven central folder" do
      expect(described_class.check_status_url(project)).to eq("https://repo1.maven.org/maven2/javax/faces/javax.faces-api")
    end

    context "with atlassian provider" do
      let!(:version) { create(:version, project: project, repository_sources: [PackageManager::Maven::Atlassian::REPOSITORY_SOURCE_NAME], number: "2.0.0") }

      it "returns link to atlassian folder" do
        expect(described_class.check_status_url(project.reload)).to eq("https://packages.atlassian.com/maven-central-local/javax/faces/javax.faces-api")
      end
    end

    context "with hortonworks provider" do
      let!(:version) { create(:version, project: project, repository_sources: [PackageManager::Maven::Hortonworks::REPOSITORY_SOURCE_NAME], number: "2.0.0") }

      it "returns link to atlassian folder" do
        expect(described_class.check_status_url(project.reload)).to eq("https://repo.hortonworks.com/content/groups/releases/javax/faces/javax.faces-api")
      end
    end
  end

  describe ".mapping" do
    context "with missing pom" do
      it "should return nil" do
        allow(described_class).to receive(:download_pom).and_raise(PackageManager::Maven::POMNotFound.new("https://a-spring-url"))

        expect(described_class.mapping({group_id: "org", artifact_id: "foo", version: "1.0.0"})).to eq(nil)
      end
    end
  end

  describe "#download_url" do
    let(:project) { create(:project, name: "javax.faces:javax.faces-api", platform: described_class.formatted_name.demodulize) }

    it "returns link to maven central jar file" do
      expect(described_class.download_url(project.name, "2.3")).to eq("https://repo1.maven.org/maven2/javax/faces/javax.faces-api/2.3/javax.faces-api-2.3.jar")
    end

    context "with atlassian provider" do
      let!(:version) { create(:version, project: project, repository_sources: [PackageManager::Maven::Atlassian::REPOSITORY_SOURCE_NAME], number: "2.0.0") }

      it "returns link to atlassian folder" do
        expect(described_class.download_url(project.name, "2.0.0")).to eq("https://packages.atlassian.com/maven-central-local/javax/faces/javax.faces-api/2.0.0/javax.faces-api-2.0.0.jar")
      end
    end

    context "with hortonworks provider" do
      let!(:version) { create(:version, project: project, repository_sources: [PackageManager::Maven::Hortonworks::REPOSITORY_SOURCE_NAME], number: "2.0.0") }

      it "returns link to atlassian folder" do
        expect(described_class.download_url(project.name, "2.0.0")).to eq("https://repo.hortonworks.com/content/groups/releases/javax/faces/javax.faces-api/2.0.0/javax.faces-api-2.0.0.jar")
      end
    end
  end

  describe ".project(name)" do
    it "returns the expected project data" do
      allow(described_class)
        .to receive(:latest_version)
        .and_return("2.3")

      expected = {
        name: "javax.faces:javax.faces-api",
        path: "javax.faces/javax.faces-api", # This is the proper format for a maven-repository.com path component, which differs from maven.org format (dots vs slashes)
        group_id: "javax.faces",
        artifact_id: "javax.faces-api",
        latest_version: "2.3",
      }

      expect(described_class.project("javax.faces:javax.faces-api")).to eq(expected)
    end
  end

  describe ".one_version" do
    it "retrieves a single version" do
      allow(described_class)
        .to receive(:download_pom)
        .and_raise(PackageManager::Maven::POMNotFound.new("https://a-maven-central-url"))

      expect(PackageManager::Maven::MavenCentral.one_version("org.foo:bar", "1.0.0")). to eq(nil)
    end

  end

  describe ".versions" do
    it "returns the expected version data" do
      allow(described_class)
        .to receive(:versions)
        .and_return([{ number: "2.3", published_at: "2019-06-05T10:50:00Z" }])

      project = described_class.project("javax.faces:javax.faces-api")
      expect(described_class.versions(project, "javax.faces:javax.faces-api")).to eq([
        { number: "2.3", published_at: "2019-06-05T10:50:00Z" }
      ])
    end

    it "skips versions that can't be parsed" do
      expect(described_class)
        .to receive(:get_raw)
          .with("https://repo1.maven.org/maven2/com/google/api/grpc/proto-google-common-protos/maven-metadata.xml")
          .and_return(File.open("spec/fixtures/proto-google-common-protos-0.1.9.pom").read)
      allow(described_class)
        .to receive(:get_pom)
          .with("com.google.api.grpc", "proto-google-common-protos", "0.1.9")
          .and_raise(Ox::ParseError.new(""))

      # TODO: these are probably bugs... it's using the version 3.2.0/etc of a depdendency and looking that up on itself
      allow(described_class)
        .to receive(:get_pom)
          .with("com.google.api.grpc", "proto-google-common-protos", "3.2.0")
          .and_raise(Ox::ParseError.new(""))
      allow(described_class)
        .to receive(:get_pom)
          .with("com.google.api.grpc", "proto-google-common-protos", "${api.version}")
          .and_raise(Ox::ParseError.new(""))

      expect(described_class.versions(nil, "com.google.api.grpc:proto-google-common-protos")).to eq([])
    end
  end

  describe "mapping_from_pom_xml" do
    let(:pom) { Ox.parse(File.open("spec/fixtures/proto-google-common-protos-0.1.9.pom").read) }
    let(:parent_pom) { Ox.parse("<project><licenses><license><name>unknown</name></license></licenses><url>https://github.com/googleapis/googleapis</url></project>") }
    let(:parent_project) { { name: "com.google.api.grpc:proto-google-common-parent", groupId: "com.google.api.grpc", artifactId: "proto-google-common-parent", versions: [{ number: "1.0", published_at: Time.now.to_s }] } }
    let(:parsed) { described_class.mapping_from_pom_xml(pom) }

    context "with parsed pom" do
      before do
        allow(described_class)
          .to receive(:project)
          .and_return(parent_project)
        allow(described_class)
          .to receive(:get_pom)
          .with("com.google.api.grpc", "proto-google-common-parent", "0.1.9")
          .and_return(parent_pom)
      end

      it "to find license" do
        # parent license should be overwritten by direct pom
        expect(parsed[:licenses]).to eq("Apache-2.0")
      end

      it "to find description" do
        expect(parsed[:description]).to eq("PROTO library for proto-google-common-protos")
      end

      it "to find homepage" do
        # homepage value should come from parent pom
        expect(parsed[:homepage]).to eq("https://github.com/googleapis/googleapis")
      end

      it "to find repository url" do
        expect(parsed[:repository_url]).to eq("https://github.com/googleapis/googleapis-dummy")
      end
    end

    it "to stop calling parent poms at maximum depth" do
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

  describe ".get_pom(group_id, artifact_id, version)" do
    context "with no relocation" do
      it "returns the expected data" do
        simple_pom = Ox.parse("<project></project>")

        allow(described_class).to receive(:download_pom)
          .and_return(simple_pom)

        expect(described_class.get_pom("group_id", "artifact_id", "version"))
          .to eq(simple_pom)
      end
    end

    context "with a simple relocation" do
      it "returns the expected data" do
        simple_pom = Ox.parse("<project></project>")
        redirect_pom = Ox.parse("<project><distributionManagement><relocation><groupId>group.id.2</groupId></relocation></distributionManagement></project>")

        allow(described_class).to receive(:download_pom)
          .and_return(redirect_pom, simple_pom)

        expect(described_class.get_pom("group_id", "artifact_id", "version"))
          .to eq(simple_pom)
      end
    end

    context "with a broken relocation" do
      it "returns the expected data" do
        redirect_pom = Ox.parse("<project><distributionManagement><relocation><groupId>group_id_2</groupId></relocation></distributionManagement></project>")

        call_count = 0
        allow(described_class).to receive(:download_pom) do
          call_count += 1
          call_count > 1 ? raise(Faraday::Error) : redirect_pom
        end

        expect(described_class.get_pom("group_id", "artifact_id", "version"))
          .to eq(redirect_pom)
      end
    end

    context "with an infinite relocation loop" do
      it "terminates" do
        redirect_pom = Ox.parse("<project><distributionManagement><relocation><groupId>group_id_2</groupId></relocation></distributionManagement></project>")
        redirect_pom_2 = Ox.parse("<project><distributionManagement><relocation><groupId>group_id</groupId></relocation></distributionManagement></project>")

        allow(described_class).to receive(:download_pom)
          .and_return(redirect_pom, redirect_pom_2)

        expect(described_class.get_pom("group_id", "artifact_id", "version"))
          .to eq(redirect_pom_2)
      end
    end
  end

  describe ".licenses(xml)" do
    context "with licences in the XML" do
      it "returns those licenses" do
        pom = Ox.parse("<project><licenses><license><name>Apache-2.0</name><url>http://www.apache.org/licenses/LICENSE-2.0.txt</url></license></licenses></project>")

        expect(described_class.licenses(pom)).to eq(["Apache-2.0"])
      end
    end

    context "with licences in the comments" do
      it "returns those licenses" do
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

        expect(described_class.licenses(pom)).to eq(["Apache-2.0"])
      end
    end

    context "with no licences" do
      it "returns empty" do
        pom = Ox.parse("<project></project>")
        expect(described_class.licenses(pom)).to be_empty
      end
    end
  end

  describe ".latest_version(names)" do
    context "with versions in the project" do
      it "returns the latest version" do
        expect(described_class)
          .to receive(:get_raw)
            .with("https://repo1.maven.org/maven2/com/tidelift/test/maven-metadata.xml")
            .and_return(File.open("spec/fixtures/tidelift-maven_metadata.xml").read)

        expect(described_class.latest_version("com.tidelift:test")).to eq("1.0.5")
      end
    end
  end
end

describe PackageManager::Maven::MavenUrl do
  describe "#legal_name?" do
    it "allows names with the format {group_id}:{artifact_name}" do
      ["com.google:guava", "junit:junit", "org.springframework.boot:spring-boot-starter-web", "org.scala-lang:scala-library"].each do |name|
        expect(described_class.legal_name?(name)).to be true
      end
    end

    it "does not allow names without the format {group_id}:{artifact_name}" do
      ["guava", "junit", "org.springframework.boot", "org.scala-lang"].each do |name|
        expect(described_class.legal_name?(name)).to be false
      end
    end
  end
end
