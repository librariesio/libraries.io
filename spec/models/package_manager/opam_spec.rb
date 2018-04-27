require 'rails_helper'

describe PackageManager::Opam do
  let(:project) { create(:project, name: 'foo', platform: described_class.name) }

  it "has formatted name of 'opam'" do
    expect(described_class.formatted_name).to eq('opam')
  end

  describe '#package_link' do
    it 'returns a link to project website' do
      expect(described_class.package_link(project)).to eq("https://opam.ocaml.org/packages/foo/")
    end

    it 'handles version' do
      expect(described_class.package_link(project, '2.0.0')).to eq("https://opam.ocaml.org/packages/foo/foo.2.0.0")
    end
  end

  describe '#install_instructions' do
    it 'returns a command to install the project' do
      expect(described_class.install_instructions(project)).to eq("opam install foo")
    end

    it 'handles version' do
      expect(described_class.install_instructions(project, '2.0.0')).to eq("opam install foo.2.0.0")
    end
  end

end