# frozen_string_literal: true

# TODO: Better place to put this?
ActiveRecord::Base.connection.execute("SET pg_trgm.similarity_threshold = 0.6;")
