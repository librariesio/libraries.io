## Individual Repository Project Search

Search a single platform for projects:

```
GET https://libraries.io/api/:platform/search?q=:project
```

---

The search endpoint accepts a sort parameter: rank, stars, dependents_count, dependent_repos_count, latest_release_published_at, contributions_count, created_at.

---

Example: ```https://libraries.io/api/github/search?q=rails```
```
[
  {
    "full_name": "rails/rails",
    "description": "Ruby on Rails",
    "fork": false,
    "created_at": "2008-04-11T02:19:47.000Z",
    "updated_at": "2018-05-08T14:18:07.000Z",
    "pushed_at": "2018-05-08T11:38:30.000Z",
    "homepage": "http://rubyonrails.org",
    "size": 163747,
    "stargazers_count": 39549,
    "language": "Ruby",
    "has_issues": true,
    "has_wiki": false,
    "has_pages": false,
    "forks_count": 16008,
    "mirror_url": null,
    "open_issues_count": 1079,
    "default_branch": "master",
    "subscribers_count": 2618,
    "uuid": "8514",
    "source_name": null,
    "license": "MIT",
    "private": false,
    "contributions_count": 2627,
    "has_readme": "README.md",
    "has_changelog": null,
    "has_contributing": "CONTRIBUTING.md",
    "has_license": "MIT-LICENSE",
    "has_coc": "CODE_OF_CONDUCT.md",
    "has_threat_model": null,
    "has_audit": null,
    "status": null,
    "last_synced_at": "2018-03-31T12:40:28.163Z",
    "rank": 28,
    "host_type": "GitHub",
    "host_domain": null,
    "name": null,
    "scm": "git",
    "fork_policy": null,
    "github_id": "8514",
    "pull_requests_enabled": null,
    "logo_url": null,
    "github_contributions_count": 2627,
    "keywords": [
      "activejob",
      "activerecord",
      "framework",
      "html",
      "mvc",
      "rails",
      "ruby"
    ]
  },
...
]
```
