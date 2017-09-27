require 'rails_helper'

describe Repository, type: :model do
  it { should have_many(:projects) }
  it { should have_many(:contributions) }
  it { should have_many(:contributors) }
  it { should have_many(:tags) }
  it { should have_many(:published_tags) }
  it { should have_many(:manifests) }
  it { should have_many(:dependencies) }
  it { should have_many(:forked_repositories) }
  it { should have_many(:repository_subscriptions) }
  it { should have_many(:web_hooks) }
  it { should have_many(:issues) }
  it { should have_one(:readme) }
  it { should belong_to(:repository_organisation) }
  it { should belong_to(:repository_user) }
  it { should belong_to(:source) }

  it { should validate_uniqueness_of(:full_name) }
  it { should validate_uniqueness_of(:uuid) }

  describe '#domain' do
    it 'should be https://github.com for GitHub repos' do
      expect(Repository.new(host_type: 'GitHub').domain).to eq('https://github.com')
    end

    it 'should be https://gitlab.com for GitLab repos' do
      expect(Repository.new(host_type: 'GitLab').domain).to eq('https://gitlab.com')
    end

    it 'should be https://bitbucket.org for Bitbucket repos' do
      expect(Repository.new(host_type: 'Bitbucket').domain).to eq('https://bitbucket.org')
    end
  end

  describe '#url' do
    it 'should be https://github.com/:full_name for GitHub repos' do
      expect(Repository.new(host_type: 'GitHub', full_name: 'rails/rails').url).to eq('https://github.com/rails/rails')
    end

    it 'should be https://gitlab.com/:full_name for GitLab repos' do
      expect(Repository.new(host_type: 'GitLab', full_name: 'rails/rails').url).to eq('https://gitlab.com/rails/rails')
    end

    it 'should be https://bitbucket.org/:full_name for Bitbucket repos' do
      expect(Repository.new(host_type: 'Bitbucket', full_name: 'rails/rails').url).to eq('https://bitbucket.org/rails/rails')
    end
  end

  describe '#watchers_url' do
    it 'should be https://github.com/:full_name/watchers for GitHub repos' do
      expect(Repository.new(host_type: 'GitHub', full_name: 'rails/rails').watchers_url).to eq('https://github.com/rails/rails/watchers')
    end

    it 'should be nil for GitLab repos' do
      expect(Repository.new(host_type: 'GitLab', full_name: 'rails/rails').watchers_url).to eq(nil)
    end

    it 'should be nil for Bitbucket repos' do
      expect(Repository.new(host_type: 'Bitbucket', full_name: 'rails/rails').watchers_url).to eq(nil)
    end
  end

  describe '#stargazers_url' do
    it 'should be https://github.com/:full_name/stargazers for GitHub repos' do
      expect(Repository.new(host_type: 'GitHub', full_name: 'rails/rails').stargazers_url).to eq('https://github.com/rails/rails/stargazers')
    end

    it 'should be nil for GitLab repos' do
      expect(Repository.new(host_type: 'GitLab', full_name: 'rails/rails').stargazers_url).to eq(nil)
    end

    it 'should be nil for Bitbucket repos' do
      expect(Repository.new(host_type: 'Bitbucket', full_name: 'rails/rails').stargazers_url).to eq(nil)
    end
  end

  describe '#forks_url' do
    it 'should be https://github.com/:full_name/network for GitHub repos' do
      expect(Repository.new(host_type: 'GitHub', full_name: 'rails/rails').forks_url).to eq('https://github.com/rails/rails/network')
    end

    it 'should be https://gitlab.com/:full_name/forks for GitLab repos' do
      expect(Repository.new(host_type: 'GitLab', full_name: 'rails/rails').forks_url).to eq('https://gitlab.com/rails/rails/forks')
    end

    it 'should be nil for Bitbucket repos' do
      expect(Repository.new(host_type: 'Bitbucket', full_name: 'rails/rails').forks_url).to eq(nil)
    end
  end

  describe '#issues_url' do
    it 'should be https://github.com/:full_name/issues for GitHub repos' do
      expect(Repository.new(host_type: 'GitHub', full_name: 'rails/rails').issues_url).to eq('https://github.com/rails/rails/issues')
    end

    it 'should be https://gitlab.com/:full_name/issues for GitLab repos' do
      expect(Repository.new(host_type: 'GitLab', full_name: 'rails/rails').issues_url).to eq('https://gitlab.com/rails/rails/issues')
    end

    it 'should be https://bitbucket.org/:full_name/issues for Bitbucket repos' do
      expect(Repository.new(host_type: 'Bitbucket', full_name: 'rails/rails').issues_url).to eq('https://bitbucket.org/rails/rails/issues')
    end
  end

  describe '#contributors_url' do
    it 'should be https://github.com/:full_name/graphs/contributors for GitHub repos' do
      expect(build(:repository, host_type: 'GitHub').contributors_url).to eq('https://github.com/rails/rails/graphs/contributors')
    end

    it 'should be https://gitlab.com/:full_name/graphs/master for GitLab repos' do
      expect(build(:repository, host_type: 'GitLab').contributors_url).to eq('https://gitlab.com/rails/rails/graphs/master')
    end

    it 'should be nil for Bitbucket repos' do
      expect(build(:repository, host_type: 'Bitbucket').contributors_url).to eq(nil)
    end
  end

  describe '#blob_url' do
    context 'with no args' do
      it 'should be https://github.com/:full_name/blob/master/ for GitHub repos' do
        expect(build(:repository, host_type: 'GitHub').blob_url).to eq('https://github.com/rails/rails/blob/master/')
      end

      it 'should be https://gitlab.com/:full_name/blob/master for GitLab repos' do
        expect(build(:repository, host_type: 'GitLab').blob_url).to eq('https://gitlab.com/rails/rails/blob/master/')
      end

      it 'should be https://bitbucket.org/:full_name/src/master/ for Bitbucket repos' do
        expect(build(:repository, host_type: 'Bitbucket').blob_url).to eq('https://bitbucket.org/rails/rails/src/master/')
      end
    end
  end

  describe '#source_url' do
    it 'should be https://github.com/:source_name for GitHub repos' do
      expect(Repository.new(host_type: 'GitHub', source_name: 'fails/fails').source_url).to eq('https://github.com/fails/fails')
    end

    it 'should be https://gitlab.com/:source_name for GitLab repos' do
      expect(Repository.new(host_type: 'GitLab', source_name: 'fails/fails').source_url).to eq('https://gitlab.com/fails/fails')
    end

    it 'should be https://bitbucket.org/:source_name for Bitbucket repos' do
      expect(Repository.new(host_type: 'Bitbucket', source_name: 'fails/fails').source_url).to eq('https://bitbucket.org/fails/fails')
    end
  end

  describe '#raw_url' do
    context 'with no args' do
      it 'should be https://github.com/:full_name/raw/master/ for GitHub repos' do
        expect(build(:repository, host_type: 'GitHub').raw_url).to eq('https://github.com/rails/rails/raw/master/')
      end

      it 'should be https://gitlab.com/:full_name/raw/master for GitLab repos' do
        expect(build(:repository, host_type: 'GitLab').raw_url).to eq('https://gitlab.com/rails/rails/raw/master/')
      end

      it 'should be https://bitbucket.org/:full_name/raw/master/ for Bitbucket repos' do
        expect(build(:repository, host_type: 'Bitbucket').raw_url).to eq('https://bitbucket.org/rails/rails/raw/master/')
      end
    end
  end

  describe '#commits_url' do
    context 'with no args' do
      it 'should be https://github.com/:full_name/raw/master/ for GitHub repos' do
        expect(build(:repository, host_type: 'GitHub').commits_url).to eq('https://github.com/rails/rails/commits')
      end

      it 'should be https://gitlab.com/:full_name/raw/master for GitLab repos' do
        expect(build(:repository, host_type: 'GitLab').commits_url).to eq('https://gitlab.com/rails/rails/commits/master')
      end

      it 'should be https://bitbucket.org/:full_name/raw/master/ for Bitbucket repos' do
        expect(build(:repository, host_type: 'Bitbucket').commits_url).to eq('https://bitbucket.org/rails/rails/commits')
      end
    end
  end

  describe '#avatar_url' do
    context 'with no args' do
      it 'should return an avatar url for GitHub repos' do
        expect(build(:repository, host_type: 'GitHub').avatar_url).to eq('https://github.com/rails.png?size=60')
      end

      it 'should return an avatar url for GitLab repos' do
        expect(build(:repository, host_type: 'GitLab').avatar_url).to eq('https://www.gravatar.com/avatar/7ae482ea784951c2d4bb56fc642619b7?s=60&f=y&d=retro')
      end

      it 'should return an avatar url for Bitbucket repos' do
        expect(build(:repository, host_type: 'Bitbucket').avatar_url).to eq('https://bitbucket.org/rails/rails/avatar/60')
      end
    end
  end
end
