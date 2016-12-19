require 'rails_helper'

describe Repositories::PlatformIO, :vcr do
  it 'has formatted name of "PlatformIO"' do
    expect(Repositories::PlatformIO.formatted_name).to eq('PlatformIO')
  end

  describe '#package_link' do
    let(:project) { create(:project, name: 'foo', platform: 'PlatformIO', pm_id: 1) }

    it 'returns a link to project website' do
      expect(Repositories::PlatformIO.package_link(project)).to eq('http://platformio.org/lib/show/1/foo')
    end

    it 'ignores version' do
      expect(Repositories::PlatformIO.package_link(project, '2.0.0')).to eq('http://platformio.org/lib/show/1/foo')
    end
  end
end
