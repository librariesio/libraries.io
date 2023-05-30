# frozen_string_literal: true

module ManifestKindCounting
  def self.build_project_where_clause(packages)
    project_table = Project.arel_table

    packages.reduce(Arel::Nodes::False.new) do |clause, package|
      clause.or(
        project_table.grouping(
          project_table.lower(project_table[:platform]).eq(package[0].downcase).and(
            project_table[:name].eq(package[1])
          )
        )
      )
    end
  end
end

namespace :manifest do
  desc "Tests a sampling of project's versions to count occurrences of different manifest kinds"
  task :kind_counter, %i[package_list output_file] => :environment do |_t, args|
    raise "Provide package_list csv file with columns [package_platform, package_name]" unless args[:package_list].present?

    output_file = args[:output_file] || File.join(__dir__, "output", "manifest_kind_count.json")

    packages = CSV.read(args[:package_list])

    global_tallies = { cursor: 0 }.with_indifferent_access

    previous_tallies = File.exist?(output_file) && File.read(output_file)
    if previous_tallies.present?
      global_tallies = JSON.parse(previous_tallies).with_indifferent_access
      packages = packages[global_tallies[:cursor]..]
    end

    slice_size = 1000

    packages&.each_slice(slice_size) do |packages_slice|
      repository_ids = Project
                         .where(ManifestKindCounting.build_project_where_clause(packages_slice))
                         .limit(slice_size)
                         .distinct
                         .pluck(:repository_id)
                         .compact
                         .join(",")

      ActiveRecord::Base.connection.execute(
        <<-SQL
            select
              platform,
              kinds,
              count(*)
            from
              (
                select
                  lower(platform) as platform,
                  array_agg(
                    distinct kind
                    order by
                      kind asc
                  ) as kinds
                from
                  manifests
                where
                  repository_id in (#{repository_ids})
                group by
                  platform,
                  repository_id
              ) as platform_kinds
            group by
              platform,
              kinds
            order by
              platform,
              kinds;
        SQL
      ).each do |platform_kind_count|
        platform = platform_kind_count["platform"]
        kind = platform_kind_count["kinds"]
        count = platform_kind_count["count"]

        global_tallies[platform] ||= {}
        global_tallies[platform][kind] ||= 0

        global_tallies[platform][kind] += count
      end
    end

    global_tallies[:cursor] = global_tallies[:cursor] + slice_size

    File.write(
      output_file,
      JSON.pretty_generate(global_tallies)
    )
  end
end
