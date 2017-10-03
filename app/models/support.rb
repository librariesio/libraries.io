class Support < ApplicationRecord

	belongs_to :supportable, polymorphic: true
	validates_presence_of :supportable

end
