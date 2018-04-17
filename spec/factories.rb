require 'securerandom'

FactoryBot.define do
  sequence :email do |n|
    "email#{n}@gmail.com"
  end

  sequence :name do |n|
    "rails#{n}"
  end

  sequence :login do |n|
    "andrew#{n}"
  end

  sequence :repository_url do |n|
    "https://github.com/rails/rails#{n}"
  end

  factory :project do
    name
    platform        'Rubygems'
    description     'Ruby on Rails is a full-stack web framework optimized for programmer happiness and sustainable productivity. It encourages beautiful code by favoring convention over configuration.'
    homepage        'http://rubyonrails.org/'
    language        'Ruby'
    licenses        'MIT'
    keywords_array  ['web']
    repository_url
  end

  factory :platform do
    name 'Rubygems'
    project_count 100_000
  end

  factory :version do
    project
    number '1.0.0'
    published_at 1.day.ago
  end

  factory :dependency do
    version
    project
    kind 'runtime'
    platform 'Rubygems'
    project_name 'rails'
    requirements '~> 4.2'
  end

  factory :repository_dependency do
    manifest
    project
    platform 'Rubygems'
    project_name 'rails'
    requirements '~> 4.2'
  end

  factory :manifest do
    repository
    filepath 'Gemfile'
    platform 'Rubygems'
  end

  factory :tag do
    repository
    name '1.0.0'
    sha  { SecureRandom.hex }
    published_at 1.day.ago
  end

  factory :issue do
    repository
    sequence(:uuid)
    sequence(:number)
    state "open"
    title "I found a bug"
    body "Please fix it"
    labels ['help wanted', 'easy']
    locked false
    repository_user
    comments_count 1
    host_type 'GitHub'
  end

  factory :contribution do
    repository
    repository_user
    count 1
  end

  factory :project_suggestion do
    project
    user
    notes "Details in the readme"
  end

  factory :project_mute do
    project_id 1
    user_id 1
  end

  factory :repository_user do
    login
    name 'Andrew Nesbitt'
    user_type 'User'
    company 'Libraries.io'
    blog 'http://nesbitt.io'
    location 'Somerset, UK'
    email 'andrew@libraries.io'
    bio 'Developer of things'
    followers 1
    following 2
    sequence(:uuid)
    host_type 'GitHub'
  end

  factory :repository_organisation do
    login
    sequence(:uuid)
    host_type 'GitHub'
    name 'Libraries.io'
    blog 'https://libraries.io'
    email 'support@libraries.io'
    location 'Bath, UK'
    bio 'Open source things'
  end

  factory :subscription do
    user
    project
  end

  factory :repository_subscription do
    user
    repository
  end

  factory :repository do
    host_type   'GitHub'
    full_name   'rails/rails'
    description 'Ruby on Rails'
    language    'Ruby'
    fork        false
    homepage    'http://rubyonrails.org'
    repository_organisation
    private false
    stargazers_count 10_000
    size 1000
    default_branch 'master'
    forks_count 1
  end

  factory :user do
    email
    after(:create) do |user, _evaluator|
      create(:identity, user: user)
    end
  end

  factory :identity do
    user
    repository_user
    sequence(:uid)
    provider 'github'
    nickname { Faker::Name.name.parameterize }
    token { SecureRandom.hex }
    avatar_url { "http://github.com/#{Faker::Name.name.parameterize}.png" }
  end

  factory :repository_permission do
    user
    repository
    pull true
  end

  factory :web_hook do
    repository
    user
    url 'http://google.com'
  end

  factory :api_key do
    user
    access_token { SecureRandom.hex }
  end

  factory :auth_token do
    login
    token { SecureRandom.hex }
  end

  factory :readme do
    repository
    html_body 'Welcome to the jungle'
  end
end
