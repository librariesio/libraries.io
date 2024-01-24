# frozen_string_literal: true

require "rails_helper"

RSpec.describe PrereleaseForPlatform do
  describe ".prerelease?" do
    context "with rubygems" do
      [["1", false],
       ["1a", true]].each do |version_number, result|
         it "matches #{version_number}" do
           expect(described_class.prerelease?(version_number: version_number, platform: "rubygems")).to eq(result)
         end
       end
    end

    context "with pypi" do
      [["1", false],
       ["1a", true],
       ["1b", true],
       ["1c", false],
       ["1rc", true],
       ["1dev", true],
       ["1dev-", true],
       ["1dev0", true],
       ["1devv", false]].each do |version_number, result|
         it "matches #{version_number}" do
           expect(described_class.prerelease?(version_number: version_number, platform: "pypi")).to eq(result)
         end
       end
    end

    context "any other platform" do
      it "returns nil" do
        expect(described_class.prerelease?(version_number: "1pre", platform: "whatever")).to eq(nil)
      end
    end
  end
end
