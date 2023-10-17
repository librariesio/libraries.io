# frozen_string_literal: true

namespace :auth_tokens do
  desc "Verify each authorized AuthToken that it's still authorized"
  task :reverify_authorized, %i[count start] => :environment do |_task, args|
    exit if ENV["READ_ONLY"].present?
    args.with_defaults(count: 500, start: nil)
    last_id = "none"

    begin
      AuthToken
        .authorized
        .in_batches(of: args.count, start: args.start)
        .each do |token_batch|
          token_batch.each do |token|
            result = token.still_authorized?
            fresh_login = token.github_client.user[:login]

            token.update(
              login: (fresh_login || token.login),
              authorized: result
            )

            unless result
              StructuredLog.capture(
                "AUTH_TOKEN_MARKED_EXPIRED",
                {
                  token_id: token.id,
                  authorized: result,
                  created_at: token.created_at,
                }
              )
            end

            last_id = token.id
          end

          # Don't necessarily have to worry about rate limit #still_authorized? /should/ still work
          # because a rate limit means we auth'ed successfully. But we can still pace ourselves.
          sleep 1
        end
    rescue StandardError, Interrupt => e
      puts "\n\n### Last AuthToken id processed: #{last_id} \n\n\n"
      raise e
    end
  end
end
