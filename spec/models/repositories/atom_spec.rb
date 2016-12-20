require 'rails_helper'

describe Repositories::Atom, :vcr do
  it 'has formatted name of "Atom"' do
    expect(described_class.formatted_name).to eq('Atom')
  end

  describe '#package_link' do
    let(:project) { create(:project, name: 'foo', platform: described_class.name) }

    it 'returns a link to project website' do
      expect(described_class.package_link(project)).to eq("https://atom.io/packages/foo")
    end

    it 'ignores version' do
      expect(described_class.package_link(project, '2.0.0')).to eq("https://atom.io/packages/foo")
    end
  end

  describe 'download_url' do
    it 'returns a link to project tarball' do
      expect(described_class.download_url('foo', '1.0.0')).to eq("https://www.atom.io/api/packages/foo/versions/1.0.0/tarball")
    end
  end
end
