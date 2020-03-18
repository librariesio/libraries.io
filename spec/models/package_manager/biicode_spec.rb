# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Biicode do
  it 'has formatted name of "biicode"' do
    expect(described_class.formatted_name).to eq("biicode")
  end

  it "is hidden" do
    expect(described_class::HIDDEN).to be true
  end
end
