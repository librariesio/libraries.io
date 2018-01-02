# Preview all emails at http://localhost:3000/rails/mailers/notice_mailer
class NoticeMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/notice_mailer/tidelift
  def tidelift
    user = User.new({email: 'foo@bar.com'})
    NoticeMailer.tidelift(user)
  end
end
