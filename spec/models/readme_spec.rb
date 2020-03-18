# frozen_string_literal: true

require "rails_helper"

describe Readme, type: :model do
  it { should belong_to(:repository) }

  it { should validate_presence_of(:html_body) }
  it { should validate_presence_of(:repository) }

  describe "supported_format?" do
    it "does supports textile readmes" do
      expect(described_class.supported_format?("readme.textile")).to be true
    end

    it "does supports org readmes" do
      expect(described_class.supported_format?("readme.org")).to be true
    end

    it "does supports creole readmes" do
      expect(described_class.supported_format?("readme.creole")).to be true
    end

    it "does supports asciidoctor readmes" do
      expect(described_class.supported_format?("readme.asciidoc")).to be true
    end

    it "does supports restructuredtext readmes" do
      expect(described_class.supported_format?("readme.rst")).to be true
    end

    it "does supports pod readmes" do
      expect(described_class.supported_format?("readme.pod")).to be true
    end

    it "does supports rdoc readmes" do
      expect(described_class.supported_format?("readme.rdoc")).to be true
    end

    it "does not support wikicloth readmes" do
      expect(described_class.supported_format?("readme.mediawiki")).to be false
    end
  end
end
