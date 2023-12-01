# frozen_string_literal: true

require "rails_helper"

describe ActiveRecord do
  describe "with_statement_timeout" do
    it "should run the block with a temporary statement_timeout" do
      before_timeout = ActiveRecord::Base.connection.exec_query("SHOW statement_timeout;").first["statement_timeout"]
      temporary_timeout = ActiveRecord::Base.connection.with_statement_timeout(1234) do
        ActiveRecord::Base.connection.exec_query("SHOW statement_timeout;").first["statement_timeout"]
      end
      after_timeout = ActiveRecord::Base.connection.exec_query("SHOW statement_timeout;").first["statement_timeout"]

      expect(after_timeout).to eq(before_timeout)
      expect(temporary_timeout).to eq("1234s")
    end
  end

  it "should not affect the timeouts of other connections" do
    current_conn = ActiveRecord::Base.connection
    other_conn = ActiveRecord::Base.connection_pool.checkout

    begin
      current_conn.with_statement_timeout(123_456) do |conn|
        expect(conn.fetch_statement_timeout).to eq("123456s")
        expect(other_conn.fetch_statement_timeout).to eq("5min")
      end
      expect(current_conn.fetch_statement_timeout).to eq("5min")
      expect(other_conn.fetch_statement_timeout).to eq("5min")
    ensure
      ActiveRecord::Base.connection_pool.checkin(other_conn)
    end
  end

  describe "where_with_tuples" do
    let(:projects) { create_list(:project, 3) }

    it "queries against one column" do
      result = Project.where_with_tuples([:name], projects.map { |p| [p.name] })
      expect(result).to match_array(projects)
    end
  
    it "queries against two columns" do
      result = Project.where_with_tuples(%i[platform name], projects.pluck(:platform, :name))
      expect(result).to match_array(projects)
    end
  
    it "queries against three columns" do
      result = Project.where_with_tuples(%i[platform name id], projects.pluck(:platform, :name, :id))
      expect(result).to match_array(projects)
    end
  
    it "queries using the given tuples" do
      result = Project.where_with_tuples(%i[platform name], projects[0, 1].pluck(:platform, :name))
      expect(result).to match_array(projects[0, 1])
    end
  
    context "with a hidden project" do
      let!(:invisible_project) { create(:project, status: "Hidden") }
  
      it "queries with the given scope" do
        result = Project.visible.where_with_tuples(%i[platform name], projects.pluck(:platform, :name))
        expect(result).to match_array(projects)
        expect(result).not_to include(invisible_project)
      end
    end
  
    it "disallows mismatched columns and tuples" do
      expect do
        Project.where_with_tuples(%i[platform name id], projects.pluck(:platform, :name))
      end.to raise_error("Column count must equal tuple count")
    end
  
    it "sanitizes tuples" do
      # ActiveRecord has great sanitization already, this is just a regression check to make sure we're always sanitizing input.
      query = Project.select("name").where_with_tuples([:name], [["a,b)' ; --"]])
      sql = query.to_sql
      expect(sql).to eq(%!SELECT "projects"."name" FROM "projects" WHERE ((name) IN (('a,b)'' ; --')))!)
      expect(query.load).to eq([])
    end
  end
end
