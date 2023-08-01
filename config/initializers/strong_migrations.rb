# frozen_string_literal: true

# only enforce "safe" migrations after a date
StrongMigrations.start_after = 20230712195318 # rubocop:disable Style/NumericLiterals

# TODO: after the next postgres upgrade, we can upgrade the strong_migrations gem.
StrongMigrations.target_postgresql_version = "9.6"
