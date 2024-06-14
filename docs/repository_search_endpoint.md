## Individual Repository Search

The repository search endpoint allows you to search (currently Github, Gitlab, or Bitbucket) for the repositories which contain the query string. The request will find all projects that contain the search parameter within the title.

Caution: This search will NOT query the keywords of each project, the title has to contain the query string.

For example, to search for 'Ruby on Rails' you could pass 'rails' as your search query parameter as the repository title is 'rails/rails'.

#### Basic Request Format

A basic request to the repository search endpoint with minimal parameters will look like this:

Example: ```GET https://libraries.io/api/:platform/search?q=:project```

#### Sorting the Response

It is also possible to sort the response of repositories by:

- rank
- stars
- dependents_count
- dependent_repos_count
- latest_release_published_at
- contributions_count
- created_at

In order to pass a sort parameter, append the basic endpoint request with:

```
sort=:sort_method
```

The entire endpoint with search parameter will look like this:
```
https://libraries.io/api/:platform/search?1=:project&sort=:sort_method
```

### Response

The response body will be a collection of all the repositories containing that query string.

The current first response for ```GET https://libraries.io/api/github/search?q=rails``` will return:
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

#### Edge Cases

- If no repositories are found with the passed query string, the endpoint will return an empty array with a status code of 200.
