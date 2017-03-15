require 'rails_helper'

describe PackageManager::Go do
  let(:project) { create(:project, name: 'foo', platform: described_class.name) }

  it 'has formatted name of "Go"' do
    expect(described_class.formatted_name).to eq('Go')
  end

  describe '#package_link' do
    it 'returns a link to project website' do
      expect(described_class.package_link(project)).to eq("http://go-search.org/view?id=foo")
    end

    it 'ignores version' do
      expect(described_class.package_link(project, '2.0.0')).to eq("http://go-search.org/view?id=foo")
    end
  end

  describe '#documentation_url' do
    it 'returns a link to project website' do
      expect(described_class.documentation_url('foo')).to eq("http://godoc.org/foo")
    end

    it 'ignores version' do
      expect(described_class.documentation_url('foo', '2.0.0')).to eq("http://godoc.org/foo")
    end
  end

  describe '#install_instructions' do
    it 'returns a command to install the project' do
      expect(described_class.install_instructions(project)).to eq("go get foo")
    end

    it 'ignores version' do
      expect(described_class.install_instructions(project, '2.0.0')).to eq("go get foo")
    end
  end
end
