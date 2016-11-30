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
    repository_url  'https://github.com/rails/rails'
  end

  factory :project_mute do
    project_id 1
    user_id 1
  end

  factory :github_user do
    login 'andrew'
  end

  factory :github_organisation do
    login 'rails'
  end

  factory :github_repository do
    full_name   'rails/rails'
    description 'Ruby on Rails'
    language    'Ruby'
    fork        false
    homepage    'http://rubyonrails.org'
    github_organisation
    stargazers_count 10_000
  end

  factory :user do
    uid { SecureRandom.hex }
    nickname { Faker::Name.name.parameterize }
    email
    token { SecureRandom.hex }
    location { Faker::Address.country unless [0,1,2].sample == 0 }
  end
end
