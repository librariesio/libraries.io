# frozen_string_literal: true

env = {
  "production" => Rainbow("prod").red,
  "development" => Rainbow("dev").green,
  "test" => Rainbow("test").yellow,
}.fetch(ENV["RAILS_ENV"] || ENV.fetch("RACK_ENV", nil), "dev")

IRB.conf[:PROMPT][:DEFAULT] = {
  PROMPT_I: "#{env}>%N(%m):%03n:%i> ",
  PROMPT_N: "#{env}>%N(%m):%03n:%i> ",
  PROMPT_S: "#{env}>%N(%m):%03n:%i%l ",
  PROMPT_C: "#{env}>%N(%m):%03n:%i* ",
  RETURN: "=> %s\n",
}

IRB.conf[:USE_MULTILINE] = false
IRB.conf[:USE_AUTOCOMPLETE] = false

require "./.irbrc.local" if File.exist?("./.irbrc.local.rb")
