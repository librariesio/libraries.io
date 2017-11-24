class NoticeMailer < ApplicationMailer
  def tidelift(user)
    @user = user
    mail to: user.email,
         subject: 'Libraries.io is joining Tidelift',
         reply_to: 'support@libraries.io'
  end
end
