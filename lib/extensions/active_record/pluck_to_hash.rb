# frozen_string_literal: true

# from https://github.com/girishso/pluck_to_hash/
#
# Copyright (c) 2015 Girish S
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module PluckToHash
  extend ActiveSupport::Concern

  module ClassMethods
    def pluck_to_hash(*keys)
      block_given = block_given?
      hash_type = keys[-1].is_a?(Hash) ? keys.pop.fetch(:hash_type, HashWithIndifferentAccess) : HashWithIndifferentAccess

      keys, formatted_keys = format_keys(keys)
      keys_one = keys.size == 1

      all.load.pluck(*keys).map do |row|
        value = hash_type[formatted_keys.zip(keys_one ? [row] : row)]
        block_given ? yield(value) : value
      end
    end

    private

    def format_keys(keys)
      if keys.blank?
        [column_names, column_names]
      else
        [
          keys,
          keys.map do |k|
            case k
            when String
              k.split(/\bas\b/i)[-1].strip.to_sym
            when Symbol
              k
            end
          end,
        ]
      end
    end
  end
end

ActiveRecord::Base.include PluckToHash
