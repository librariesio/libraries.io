require 'rails_helper'

describe PackageManager::Bower do
  let(:project) { create(:project, name: 'foo', platform: described_class.formatted_name) }

  it 'has formatted name of "Bower"' do
    expect(PackageManager::Bower.formatted_name).to eq('Bower')
  end

  describe '#install_instructions' do
    it 'returns a command to install the project' do
      expect(described_class.install_instructions(project)).to eq("bower install foo")
    end

    it 'handles version' do
      expect(described_class.install_instructions(project, '2.0.0')).to eq("bower install foo#2.0.0")
    end
  end
end
