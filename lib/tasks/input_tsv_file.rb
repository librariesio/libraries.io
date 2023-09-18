# frozen_string_literal: true

class InputTsvFile
  def initialize(file, col_sep = "\t")
    @file = file
    @col_sep = col_sep
  end

  def in_batches(batch_size: 50, &block)
    data.in_groups_of(batch_size, false).each(&block)
  end

  def count
    data.count
  end

  private

  def data
    @data ||= CSV.read(
      @file,
      col_sep: @col_sep,
      headers: false,
      skip_blanks: true
    )
  end
end
