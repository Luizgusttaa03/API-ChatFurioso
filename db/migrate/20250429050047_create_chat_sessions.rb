# frozen_string_literal: true

class CreateChatSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :chat_sessions do |t|
      t.string :uuid, null: false

      t.timestamps
    end
    add_index :chat_sessions, :uuid, unique: true
  end
end
