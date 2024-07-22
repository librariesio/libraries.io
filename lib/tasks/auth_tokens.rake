# frozen_string_literal: true

namespace :auth_tokens do
  desc <<~DESC
    Verify each authorized AuthToken that it's still authorized

      batch_size [Integer, nil]: How many AuthTokens to process per batch (default: 500)
      start [String, nil] The AuthToken id to start from: The AuthToken id to start from (default: nil)
  DESC
  task :reverify_authorized, %i[batch_size start] => :environment do |_task, args|
    args.with_defaults(batch_size: 500, start: nil)
    last_id = "none"

    begin
      AuthToken
        .authorized
        .find_in_batches(batch_size: args.batch_size, start: args.start).each do |token_batch|
          token_batch.each do |token|
            result = token.still_authorized?
            if result
              token.login = token.github_client.user[:login]
              token.scopes = token.fetch_auth_scopes
            else
              token.authorized = false
            end

            token.save!

            unless result
              StructuredLog.capture(
                "AUTH_TOKEN_MARKED_EXPIRED",
                {
                  auth_token_id: token.id,
                  authorized: result,
                  created_at: token.created_at,
                }
              )
            end

            last_id = token.id

            # Don't necessarily have to worry about rate limit #still_authorized? /should/ still work
            # because a rate limit means we auth'ed successfully. But we can still pace ourselves.
            sleep 1
          rescue Octokit::TooManyRequests
            # Tokens can still be authorized but may have exhausted their API limit while making
            # these calls. For these tokens do not mark them as unauthorized but keep going
            # through the loop.
            last_id = token&.id
            next
          end
        end
    rescue StandardError, Interrupt => e
      StructuredLog.capture(
        "AUTH_TOKEN_REVERIFY_ERROR",
        {
          last_token_id: last_id,
          error_klass: e.class,
          error_message: e.message,
        }
      )

      puts "\n\n### Last AuthToken id processed: #{last_id} \n\n\n"
      raise e
    end
  end
end
