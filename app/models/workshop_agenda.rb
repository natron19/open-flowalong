class WorkshopAgenda < ApplicationRecord
  belongs_to :workshop_brief
  belongs_to :user

  validates :workshop_brief_id, presence: true
  validates :user_id,           presence: true
  validates :body,              presence: true
end
