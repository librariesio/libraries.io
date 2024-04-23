# frozen_string_literal: true

require "rails_helper"

describe RepositoryUser, type: :model do
  it { should have_many(:identities) }
  it { should have_many(:repositories) }
  it { should have_many(:source_repositories) }
  it { should have_many(:open_source_repositories) }
  it { should have_many(:contributors) }
  it { should have_many(:projects) }
  it { should have_many(:contributed_repositories) }
  it { should have_many(:fellow_contributors) }
  it { should have_many(:contributions) }

  it { should validate_presence_of(:uuid) }
  it "should validate uniqueness of uuid/host_type through index" do
    create(:repository_user, uuid: "1", host_type: "GitHub")

    expect { create(:repository_user, uuid: "1", host_type: "GitHub") }
      .to raise_error(ActiveRecord::RecordNotUnique)
  end
end
