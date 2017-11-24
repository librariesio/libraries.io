namespace :emails do
  desc 'Notify existing users about joining Tidelift'
  task tidelift_notice: :environment do
    User.find_each do |user|
      NoticeMailer.tidelift(user).deliver_now
    end
  end
end
