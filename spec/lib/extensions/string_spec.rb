# frozen_string_literal: true

require "rails_helper"

describe String do
  context "with null bytes" do
    let(:string) { "This \u0000is a string \u0000with null bytes" }

    it "should strip the null bytes" do
      expect(string.strip_null_bytes).to eq "This is a string with null bytes"
    end
  end

  context "without null bytes" do
    let(:string) { "This is a string without null bytes" }

    it "should not modify the string" do
      expect(string.strip_null_bytes).to eq string
    end
  end
end
