# frozen_string_literal: true

Rails.application.config.git_revision = if Rails.env.development?
                                          `git rev-parse HEAD`.strip
                                        else
                                          ENV.fetch("REVISION_ID", "REVISION_ID_NOT_SET")
                                        end
