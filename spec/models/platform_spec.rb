require 'rails_helper'

describe Platform, type: :model do
  subject {  build(:platform) }

  it 'should have a name that matches' do
    expect(subject.name).to eql('Rubygems')
  end

  it 'should have a project_count that matches' do
    expect(subject.project_count).to eql(100_000)
  end

  it 'should pull homepage from the package manager' do
    expect(subject.homepage).to eql('https://rubygems.org')
  end

  it 'should pull default_language from the package manager' do
    expect(subject.default_language).to eql('Ruby')
  end

  it 'should pull color from the package manager' do
    expect(subject.color).to eql('#701516')
  end
end
