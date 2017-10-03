class Support < ApplicationRecord

	has_many :support_evidences
	belongs_to :supportable, polymorphic: true
	validates_presence_of :supportable

end
