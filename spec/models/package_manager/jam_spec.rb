# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Jam do
  it 'has formatted name of "Jam"' do
    expect(described_class.formatted_name).to eq("Jam")
  end

  it "is hidden" do
    expect(described_class::HIDDEN).to be true
  end
end
