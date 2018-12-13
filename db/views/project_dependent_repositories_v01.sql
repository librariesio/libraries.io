SELECT t1.project_id, t1.id AS repository_id, t1.rank, t1.stargazers_count
FROM
(SELECT repositories.id, repositories.rank, repositories.stargazers_count, repository_dependencies.project_id
FROM repositories
INNER JOIN repository_dependencies ON repositories.id = repository_dependencies.repository_id
WHERE repositories.private = false GROUP BY repositories.id, repository_dependencies.project_id) AS t1
INNER JOIN projects ON t1.project_id = projects.id WITH NO DATA;
