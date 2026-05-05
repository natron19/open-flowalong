class WorkshopBrief < ApplicationRecord
  belongs_to :user
  has_one :workshop_agenda, dependent: :destroy

  validates :topic,            presence: true, length: { maximum: 200 }
  validates :audience,         presence: true, length: { maximum: 200 }
  validates :duration_minutes, presence: true, inclusion: { in: [60, 90, 120] }
  validates :desired_outcome,  presence: true, length: { maximum: 500 }
  validates :notes,            length: { maximum: 1000 }, allow_blank: true
end
