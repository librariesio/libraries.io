# frozen_string_literal: true

# Test performance of current Project search implementation.
# Displays relevant information about the current search configuration and
# relevant database indices/settings. Also performs equivalent queries against
# Elasticsearch implementation for comparison.
#
# Can be invoked from CLI with
# $ bin/rails search:benchmark
class SearchBenchmark
  attr_reader :count, :search_terms

  # @param count [Integer] Number of times to retry querying each term, to make sure things are warm
  # @param search_terms [Array<String>] An alternative list of words/phrases to use
  def initialize(count: 4, search_terms: nil)
    @count = count
    @search_terms = search_terms || default_search_terms
  end

  def perform
    stats = fetch_index_stats("projects")
    puts "\n--Estimated disk stats for `projects`------"
    puts "Total size on disk: #{stats.table_total_size}"
    puts "Total size of indices on disk: #{stats.table_indices_size}"
    puts "Total size of table data on disk: #{stats.table_size}"
    puts "Estimated row count: #{stats.estimated_row_count}"
    puts "Size of index on disk:"
    stats.indices.select { |name, _size| name.include?("search") }.each do |name, size|
      puts "  #{name}: #{size}"
    end

    defs = fetch_index_defs("projects")
    puts "\n--Indices for `projects`------"
    defs.select { |name, _size| name.include?("search") }.each do |name, indexdef|
      puts "#{name}:", indexdef, "\n"
    end

    example_query = pg_search_query("CooLpaCkAgE").to_sql
    puts "\n--Query------", example_query
    puts "\n--Explain------", explain_analyze(example_query)

    puts "\n--Current pg_search options------", fetch_pg_search_config

    puts "\n\nQuerying each term #{count} times..."

    run_benchmark("pg") { |term| pg_search(term) }
    run_benchmark("es") { |term| es_search(term) }

    puts "Done ✌️ "
  end

  def run_benchmark(label, &block)
    benchmarks = Benchmark.bm(15) do |bm|
      search_terms.each do |term|
        bm.report("#{label}: `#{term}`") { count.times(&block) }
      end
    end

    average = benchmarks.sum(&:real) / (search_terms.count * 3)

    puts "#{label}: Average per term per query: #{average}\n\n"
  end

  private

  def fetch_pg_search_config
    Project::DB_SEARCH_OPTIONS
  end

  def fetch_index_defs(table_name)
    ApplicationRecord.connection.execute(
      ApplicationRecord.sanitize_sql([
        <<~SQL,
          SELECT indexname AS "index_name", indexdef
          FROM pg_indexes
          WHERE tablename = :table_name
        SQL
        { table_name: table_name },
      ])
    ).to_h { |r| [r["index_name"], r["indexdef"]] }
  end

  IndexStats = Struct.new(:table_total_size, :table_indices_size, :table_size, :estimated_row_count, :indices, keyword_init: true)

  def fetch_index_stats(table_name)
    results = ApplicationRecord.connection.execute(
      ApplicationRecord.sanitize_sql([
        <<~SQL,
          SELECT i.relname AS "table_name", indexrelname AS "index_name",
            pg_size_pretty(pg_total_relation_size(relid)) AS "table_total_size",
            pg_size_pretty(pg_indexes_size(relid)) AS "table_indices_size",
            pg_size_pretty(pg_relation_size(relid)) AS "table_size",
            pg_size_pretty(pg_relation_size(indexrelid)) AS "index_size",
            reltuples::bigint AS "estimated_row_count"
          FROM pg_stat_all_indexes i JOIN pg_class c ON i.relid=c.oid
          WHERE i.relname = :table_name
        SQL
        { table_name: table_name },
      ])
    )

    IndexStats.new(
      table_total_size: results.first["table_total_size"],
      table_indices_size: results.first["table_indices_size"],
      table_size: results.first["table_size"],
      estimated_row_count: results.first["estimated_row_count"],
      indices: results.to_h { |r| [r["index_name"], r["index_size"]] }
    )
  end

  def explain_analyze(query)
    ApplicationRecord.connection.execute(
      "EXPLAIN ANALYZE #{query}"
    ).values.flatten
  end

  def pg_search_query(term)
    Project.db_search(term).paginate(per_page: 30, page: 1)
  end

  def es_search(term)
    Project.search(term).paginate(per_page: 30, page: 1).to_a
  end

  def pg_search(term)
    pg_search_query(term).to_a
  end

  def default_search_terms
    %w[
      rspec
      asdfghjkl
      rails
      deno
      urllib3
    ]
  end
end
