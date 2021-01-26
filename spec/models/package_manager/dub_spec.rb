require 'rails_helper'

describe PackageManager::Dub do
  let(:project) { create(:project, name: 'foo', platform: described_class.formatted_name) }

  it 'has formatted name of "Dub"' do
    expect(described_class.formatted_name).to eq('Dub')
  end

  describe '#package_link' do
    it 'returns a link to project website' do
      expect(described_class.package_link(project)).to eq("http://code.dlang.org/packages/foo")
    end

    it 'handles version' do
      expect(described_class.package_link(project, '2.0.0')).to eq("http://code.dlang.org/packages/foo/2.0.0")
    end
  end

  describe '#install_instructions' do
    it 'returns a command to install the project' do
      expect(described_class.install_instructions(project)).to eq("dub fetch foo")
    end

    it 'handles version' do
      expect(described_class.install_instructions(project, '2.0.0')).to eq("dub fetch foo --version 2.0.0")
    end
  end
end
