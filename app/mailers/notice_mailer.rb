class NoticeMailer < ApplicationMailer
  def tidelift(user)
    @user = user
    mail to: user.email,
         subject: 'ADD SUBJECT HERE',
         reply_to: 'info@tidelift.com'
  end
end
