# frozen_string_literal: true

require "rails_helper"

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
