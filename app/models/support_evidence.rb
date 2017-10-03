class SupportEvidence < ApplicationRecord

	belongs_to :support
	belongs_to :user

	validates_presence_of :source_url, :description, :published_at

end
