# frozen_string_literal: true

class Bugsnag
  def self.notify(error)
    Rails.logger.error(error)
  end

  def self.leave_breadcrumb(*)
    # don't need breadcrumbs if we're not notifying Bugsnag.
  end
end
