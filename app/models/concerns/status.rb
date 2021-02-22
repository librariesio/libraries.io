# frozen_string_literal: true
module Status
  def is_deprecated?
    status == 'Deprecated'
  end

  def is_removed?
    status == 'Removed'
  end

  def is_unmaintained?
    status == 'Unmaintained'
  end

  def maintained?
    !is_deprecated? && !is_removed? && !is_unmaintained?
  end
end
