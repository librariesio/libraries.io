# frozen_string_literal: true
require 'rails_helper'

describe RepositoryUserSerializer do
  subject { described_class.new(build(:repository_user)) }

  it 'should have expected attribute names' do
    expect(subject.attributes.keys).to eql([
      :github_id, :login, :user_type, :created_at, :updated_at, :name,
      :company, :blog, :location, :hidden, :last_synced_at, :email, :bio,
      :uuid, :host_type
    ])
  end
end
