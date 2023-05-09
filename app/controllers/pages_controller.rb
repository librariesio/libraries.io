# frozen_string_literal: true

class PagesController < ApplicationController
  def about; end

  def team; end

  def privacy; end

  def compatibility; end

  def data
    @platforms = Project.maintained.group(:platform).order("count_id DESC").count("id").map { |k, v| { "key" => k, "doc_count" => v } }
  end

  def terms; end

  def terms; end
end
