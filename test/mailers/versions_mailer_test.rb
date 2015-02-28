require 'test_helper'

class VersionsMailerTest < ActionMailer::TestCase
  test "new_version" do
    mail = VersionsMailer.new_version
    assert_equal "New version", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

end
