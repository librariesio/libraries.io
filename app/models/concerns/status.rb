# frozen_string_literal: true

module Status
  def deprecated?
    status == "Deprecated"
  end

  def removed?
    status == "Removed"
  end

  def unmaintained?
    status == "Unmaintained"
  end

  def maintained?
    !deprecated? && !removed? && !unmaintained?
  end
end
