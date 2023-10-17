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
            token.update_attributes(
              login: token.github_client.user[:login],
              authorized: token.still_authorized?
            )

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
