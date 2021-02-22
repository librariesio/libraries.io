# frozen_string_literal: true
require 'rails_helper'

describe PackageManager::Emacs do
  it 'has formatted name of "Emacs"' do
    expect(described_class.formatted_name).to eq('Emacs')
  end

  describe '#package_link' do
    let(:project) { create(:project, name: 'foo', platform: described_class.formatted_name) }

    it 'returns a link to project website' do
      expect(described_class.package_link(project)).to eq("http://melpa.org/#/foo")
    end

    it 'ignores version' do
      expect(described_class.package_link(project, '2.0.0')).to eq("http://melpa.org/#/foo")
    end
  end

  describe 'download_url' do
    it 'returns a link to project tarball' do
      expect(described_class.download_url('foo', '1.0.0')).to eq("http://melpa.org/packages/foo-1.0.0.tar")
    end
  end
end
