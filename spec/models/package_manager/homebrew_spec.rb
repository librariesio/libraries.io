require 'rails_helper'

describe PackageManager::Homebrew do
  let(:project) { create(:project, name: 'foo', platform: described_class.name) }

  it 'has formatted name of "Homebrew"' do
    expect(described_class.formatted_name).to eq('Homebrew')
  end

  describe '#package_link' do
    it 'returns a link to project website' do
      expect(described_class.package_link(project)).to eq("http://formulae.brew.sh/formula/foo")
    end

    it 'ignores version' do
      expect(described_class.package_link(project, '2.0.0')).to eq("http://formulae.brew.sh/formula/foo")
    end
  end

  describe '#install_instructions' do
    it 'returns a command to install the project' do
      expect(described_class.install_instructions(project)).to eq("brew install foo")
    end

    it 'ignores versions' do
      expect(described_class.install_instructions(project, '2.0.0')).to eq("brew install foo")
    end
  end
end
