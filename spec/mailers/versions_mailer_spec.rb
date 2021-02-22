# frozen_string_literal: true
require 'rails_helper'

describe VersionsMailer, type: :mailer do
  describe 'new_version' do
    let(:user) { create(:user) }
    let(:version) { create(:version) }
    let(:mail) { VersionsMailer.new_version(user, version.project, version) }

    it 'renders the subject' do
      expect(mail.subject).to eq "New release of #{version.project.name} (#{version.number}) on Rubygems"
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq [user.email]
    end

    it 'renders the sender email' do
      expect(mail['From'].to_s).to eq 'Libraries <notifications@libraries.io>'
    end

    it 'uses nickname' do
      expect(mail.body.encoded).to match(user.nickname)
    end
  end
end
