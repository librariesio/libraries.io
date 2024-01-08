# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectSearchQuery do
  subject(:search) { described_class.new(term) }

  let!(:falco) { create(:project, platform: "Cargo", language: "Rust", name: "falco", description: "bird brain") }
  let!(:slippy) { create(:project, platform: "Go", language: "Go", name: "slippy", licenses: "WTFPL") }
  let!(:slimy) { create(:project, platform: "Rubygems", language: "Ruby", name: "slimy", keywords_array: %w[laser beam]) }

  describe "#results" do
    context "with unmatching term" do
      let(:term) { "fhqwhgads" }

      it "finds by name" do
        expect(search.results).to be_empty
      end
    end

    context "with term exact match name" do
      let(:term) { "slimy" }

      it "finds by name" do
        expect(search.results).to contain_exactly(slimy)
      end
    end

    context "with term exact match description" do
      let(:term) { "brain" }

      it "finds by name" do
        expect(search.results).to contain_exactly(falco)
      end
    end

    context "with term prefix match name" do
      let(:term) { "sli" }

      it "finds projects with partial word" do
        expect(search.results).to contain_exactly(slippy, slimy)
      end
    end

    describe "filtering" do
      let(:term) { "sli" }

      context "by platform" do
        subject(:search) { described_class.new(term, platforms: ["Go"]) }

        it "limits results to any given platform" do
          expect(search.results).to contain_exactly(slippy)
        end
      end

      context "by language" do
        subject(:search) { described_class.new(term, languages: %w[Ruby Rust]) }

        it "filters out projects not of any of the given langauges" do
          expect(search.results).to contain_exactly(slimy)
        end
      end

      context "by licenses" do
        subject(:search) { described_class.new(term, licenses: ["WTFPL"]) }

        it "filters out projects without given license" do
          expect(search.results).to contain_exactly(slippy)
        end
      end

      context "by keyword" do
        subject(:search) { described_class.new(term, keywords: ["laser"]) }

        it "filters out projects without given keyword" do
          expect(search.results).to contain_exactly(slimy)
        end
      end
    end
  end
end
