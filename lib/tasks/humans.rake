namespace :humans do
  desc 'Generate a humans.txt file'
  task generate: :environment do |variable|
    token = User.first.token
    @client = Octokit::Client.new(:auto_traversal => true, access_token: token)
    File.write('./public/humans.txt', render_for_org('librariesio'))
  end
end

def render_for_org(org_name)
  teams = @client.org_teams(org_name)
  owners = teams.find{|t| t[:name] == 'Owners' }
  gh_org = @client.team_members(owners[:id])
  output = "/* TEAM */\n"
  gh_org.each do |member|
    output << render_user(member.login)
  end
  output
end

def render_user(login)
  user = @client.user(login)
  output = ""
  output << "  #{format_name(user.name,user.login)}\n"
  output << "  Site: #{user.blog}\n" unless user.blog.empty?
  output << "  Location: #{user.location}\n" unless user.location.nil?
  output + "\n"
end

def format_name(user_name, user_login)
  return user_login if user_name.nil?
  "#{user_name} (#{user_login})"
end
