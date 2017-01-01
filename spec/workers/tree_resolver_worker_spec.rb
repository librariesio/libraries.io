require 'rails_helper'

describe TreeResolverWorker do
  it "should use the default priority queue" do
    is_expected.to be_processed_in :default
  end
end
