require 'securerandom'

FactoryGirl.define do
  sequence :email do |n|
    "email#{n}@gmail.com"
  end

  sequence :name do |n|
    "rails#{n}"
  end

  sequence :login do |n|
    "andrew#{n}"
  end

  factory :project do
    name
    platform        'Rubygems'
    description     'Ruby on Rails is a full-stack web framework optimized for programmer happiness and sustainable productivity. It encourages beautiful code by favoring convention over configuration.'
    homepage        'http://rubyonrails.org/'
    language        'Ruby'
    licenses        'MIT'
    keywords_array  ['web']
    repository_url  'https://github.com/rails/rails'
  end

  factory :version do
    project
    number '1.0.0'
    published_at 1.day.ago
  end

  factory :dependency do
    version
    project
    platform 'Rubygems'
    project_name 'rails'
    requirements '~> 4.2'
  end

  factory :tag do
    repository
    name '1.0.0'
    sha  { SecureRandom.hex }
    published_at 1.day.ago
  end

  factory :issue do
    repository
    sequence(:github_id)
    sequence(:number)
    state "open"
    title "I found a bug"
    body "Please fix it"
    github_user
    comments_count 1
  end

  factory :contribution do
    repository
    github_user
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

  factory :github_user do
    login
    sequence(:github_id)
  end

  factory :github_organisation do
    login
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
    github_organisation
    private false
    stargazers_count 10_000
    size 1000
    default_branch 'master'
    forks_count 1
  end

  factory :user do
    email
    after(:create) do |user, evaluator|
      create(:identity, user: user)
    end
  end

  factory :identity do
    user
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
end
