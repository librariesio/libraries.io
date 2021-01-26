require 'rails_helper'

describe PackageManager::Julia do
  it 'has formatted name of "Julia"' do
    expect(described_class.formatted_name).to eq('Julia')
  end

  describe '#package_link' do
    let(:project) { create(:project, name: 'foo', platform: described_class.formatted_name) }

    it 'returns a link to project website' do
      expect(described_class.package_link(project)).to eq("http://pkg.julialang.org/?pkg=foo&ver=release")
    end

    it 'ignores version' do
      expect(described_class.package_link(project, '2.0.0')).to eq("http://pkg.julialang.org/?pkg=foo&ver=release")
    end
  end
end
