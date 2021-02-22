# frozen_string_literal: true
require 'rails_helper'

describe RepositoryHost::Gitlab do
  let(:repository) { build(:repository, host_type: 'GitLab') }
  let(:repository_host) { described_class.new(repository) }
end
