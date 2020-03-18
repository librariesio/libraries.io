# frozen_string_literal: true

# use amatch for faster string matching
require "fuzzy_match"
require "amatch"
FuzzyMatch.engine = :amatch
