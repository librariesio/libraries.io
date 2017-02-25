require 'rails_helper'

describe RepositoryHost::Gitlab do
  let(:repository) { build(:repository, host_type: 'GitLab') }
  let(:repository_host) { described_class.new(repository) }

  describe '#escaped_full_name' do
    it 'should escape / in full name' do
      expect(repository_host.escaped_full_name).to eq('rails%2Frails')
    end
  end
end
