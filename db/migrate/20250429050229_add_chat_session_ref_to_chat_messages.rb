# frozen_string_literal: true

class AddChatSessionRefToChatMessages < ActiveRecord::Migration[8.0]
  def change
    add_reference :chat_messages, :chat_session, null: false, foreign_key: true
  end
end
