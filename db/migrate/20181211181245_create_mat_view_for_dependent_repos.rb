class CreateMatViewForDependentRepos < ActiveRecord::Migration[5.1]

  def up
    execute 'create materialized view project_dependent_repositories as
            select t1.project_id, t1.id as repository_id, t1.rank, t1.stargazers_count
            from (SELECT "repositories".* , repository_dependencies.project_id FROM "repositories" INNER JOIN "repository_dependencies" ON "repositories"."id" = "repository_dependencies"."repository_id" WHERE "repositories"."private" = false GROUP BY repositories.id, repository_dependencies.project_id) as t1 inner join projects on t1.project_id = projects.id;'

    execute 'create index index_project_dependent_repositories_on_project_id_rank on project_dependent_repositories(project_id, rank desc nulls last, stargazers_count desc);'
  end

  def down
    execute 'drop materialized view dependent_big_repos;'
  end
end
