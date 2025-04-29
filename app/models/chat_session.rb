# frozen_string_literal: true

class ChatSession < ApplicationRecord
  has_many :chat_messages, dependent: :destroy

  validates :uuid, presence: true, uniqueness: true

  before_validation :ensure_uuid, on: :create

  private

  def ensure_uuid
    self.uuid ||= SecureRandom.uuid
  end
end
