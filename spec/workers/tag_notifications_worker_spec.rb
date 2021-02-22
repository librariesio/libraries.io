# frozen_string_literal: true
require 'rails_helper'

describe TagNotificationsWorker do
  it "should use the critical priority queue" do
    is_expected.to be_processed_in :critical
  end

  it "should send tag notifications" do
    tag = create(:tag)
    expect(Tag).to receive(:find_by_id).with(tag.id).and_return(tag)
    expect(tag).to receive(:send_notifications)
    subject.perform(tag.id)
  end
end
