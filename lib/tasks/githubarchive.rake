
# More info: https://www.githubarchive.org/

def format_result(result)
  schema = result['schema']['fields']
  result['rows'].map do |row|
    item = {}
    row['f'].each_with_index do |f,i|
      item[schema[i]['name']] = f['v']
    end
    item
  end
end

def query_archive(query)
  config = {
    'client_id'     => '933678266991-q3mi9jiu39bc5845haubfr92m35n70od.apps.googleusercontent.com',
    'service_email' => '933678266991-q3mi9jiu39bc5845haubfr92m35n70od@developer.gserviceaccount.com',
    'key'           => Rails.root.join('lib', 'google_api_key.p12').to_s,
    'project_id'    => 'winged-plate-867',
    'dataset'       => 'githubarchive:day'
  }

  bq = BigQuery::Client.new(config)
  result = bq.query(query)
  format_result(result)
end

namespace :gh do
  desc "Find repos created on a given date, eg: rake gh:repos[20150101]"
  task :new_repos, [:date] => :environment do |task, args|
    args.with_defaults(date: 1.day.ago.strftime('%Y%m%d'))

    query = "SELECT * FROM ( SELECT type, created_at, repo.name, actor.login, JSON_EXTRACT(payload, '$.ref_type') as event FROM [githubarchive:day.events_#{args.date}] WHERE type = 'CreateEvent') WHERE event CONTAINS 'repository'"

    results = query_archive(query)

    p [:results, results.count]
  end

  desc "Find repos modified on a given date, eg: rake gh:repos[20150101]"
  task :modified_repos, [:date] => :environment do |task, args|
    args.with_defaults(date: 1.day.ago.strftime('%Y%m%d'))

    # On the results 'repo.name' becomes 'repo_name'
    query = "SELECT repo.name FROM [githubarchive:day.events_#{args.date}] WHERE type CONTAINS 'PushEvent' GROUP BY repo.name"

    results = query_archive(query)

    repo_names = results.map {|r| r['repo_name']}
    GithubRepository.where(full_name: repo_names).find_each(&:update_all_info)
  end

  desc "Find repos tagged on a given date, eg: rake gh:repos[20150101]"
  task :tagged_repos, [:date] => :environment do |task, args|
    args.with_defaults(date: 1.day.ago.strftime('%Y%m%d'))

    query = "SELECT * FROM ( SELECT type, created_at, repo.name, actor.login, JSON_EXTRACT(payload, '$.ref_type') as event FROM [githubarchive:day.events_#{args.date}] WHERE type = 'CreateEvent') WHERE event CONTAINS 'tag'"

    results = query_archive(query)

    repo_names = results.map {|r| r['repo_name']}
    GithubRepository.where(full_name: repo_names).find_each(&:download_tags)
  end
end
