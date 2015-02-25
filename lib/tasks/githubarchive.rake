
config = {
  'client_id'     => '933678266991-q3mi9jiu39bc5845haubfr92m35n70od.apps.googleusercontent.com',
  'service_email' => '933678266991-q3mi9jiu39bc5845haubfr92m35n70od@developer.gserviceaccount.com',
  'key'           => Rails.root.join('lib', 'google_api_key.p12').to_s,
  'project_id'    => 'winged-plate-867',
  'dataset'       => 'githubarchive:day'
}

# More info: https://www.githubarchive.org/

namespace :gh do
  desc "Find repos created on a given date, eg: rake gh:repos[20150101]"
  task :repos, [:date] => :environment do |task, args|
    args.with_defaults(:date => '20150101')

    bq = BigQuery::Client.new(config)

    query = "SELECT * FROM ( SELECT type, created_at, repo.name, actor.login, JSON_EXTRACT(payload, '$.ref_type') as event FROM [githubarchive:day.events_#{args.date}] WHERE type = 'CreateEvent') WHERE event CONTAINS 'repository'"

    result = bq.query(query)

    result['rows'].each do |row|
      p [:repo, row['f'][2]['v']] # Yeah, I know, the output format sucks
    end

    p [:results, result['totalRows']]
  end
end
