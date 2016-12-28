require 'rails_helper'

describe PackageManager::Pypi, :vcr do
  it 'has formatted name of "PyPI"' do
    expect(described_class.formatted_name).to eq('PyPI')
  end

  describe '#package_link' do
    let(:project) { create(:project, name: 'foo', platform: described_class.name) }

    it 'returns a link to project website' do
      expect(described_class.package_link(project)).to eq("https://pypi.python.org/pypi/foo/")
    end

    it 'handles version' do
      expect(described_class.package_link(project, '2.0.0')).to eq("https://pypi.python.org/pypi/foo/2.0.0")
    end
  end
end
