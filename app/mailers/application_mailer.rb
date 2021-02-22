# frozen_string_literal: true
class ApplicationMailer < ActionMailer::Base
  default from: "Libraries <notifications@libraries.io>"
  layout 'mailer'
end
