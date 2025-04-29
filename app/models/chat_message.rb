# frozen_string_literal: true

class ChatMessage < ApplicationRecord
  belongs_to :chat_session

  validates :role, presence: true, inclusion: { in: %w[user model] }
  validates :content, presence: true
end
