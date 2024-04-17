# frozen_string_literal: true

module RepoManifests
  def download_metadata(token = nil)
    file_list = get_file_list(token)
    return if file_list.blank?

    sync_metadata(file_list)

    repository_subscriptions.each(&:update_subscriptions)
  end

  def sync_metadata(file_list)
    return if file_list.nil?

    self.has_readme       = file_list.find { |file| file.match(/^README/i) }
    self.has_changelog    = file_list.find { |file| file.match(/^CHANGE|^HISTORY/i) }
    self.has_contributing = file_list.find { |file| file.match(/^(docs\/)?(.github\/)?CONTRIBUTING/i) }
    self.has_license      = file_list.find { |file| file.match(/^LICENSE|^COPYING|^MIT-LICENSE/i) }
    self.has_coc          = file_list.find { |file| file.match(/^(docs\/)?(.github\/)?CODE[-_]OF[-_]CONDUCT/i) }
    self.has_threat_model = file_list.find { |file| file.match(/^THREAT[-_]MODEL/i) }
    self.has_audit        = file_list.find { |file| file.match(/^AUDIT/i) }
    save if changed?
  end
end
