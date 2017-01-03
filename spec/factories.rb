require 'securerandom'

FactoryGirl.define do
  sequence :email do |n|
    "email#{n}@gmail.com"
  end

  factory :project do
    name            'rails'
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

  factory :github_tag do
    github_repository
    name '1.0.0'
    sha  { SecureRandom.hex }
    published_at 1.day.ago
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
    login 'andrew'
    sequence(:github_id)
  end

  factory :github_organisation do
    login 'rails'
  end

  factory :subscription do
    user
    project
  end

  factory :repository_subscription do
    user
    github_repository
  end

  factory :github_repository do
    full_name   'rails/rails'
    description 'Ruby on Rails'
    language    'Ruby'
    fork        false
    homepage    'http://rubyonrails.org'
    github_organisation
    private false
    stargazers_count 10_000
    size 1000
  end

  factory :user do
    sequence(:uid)
    nickname { Faker::Name.name.parameterize }
    email
    token { SecureRandom.hex }
    public_repo_token { SecureRandom.hex }
  end

  factory :repository_permission do
    user
    github_repository
    pull true
  end

  factory :web_hook do
    github_repository
    user
    url 'http://google.com'
  end
end
