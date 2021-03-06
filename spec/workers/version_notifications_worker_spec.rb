# frozen_string_literal: true

require "rails_helper"

describe VersionNotificationsWorker do
  it "should send version notifications" do
    version = create(:version)
    expect(Version).to receive(:find_by_id).with(version.id).and_return(version)
    expect(version).to receive(:send_notifications)
    subject.perform(version.id)
  end
end
