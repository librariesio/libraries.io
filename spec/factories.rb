FactoryGirl.define do
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
end
