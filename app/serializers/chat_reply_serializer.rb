# frozen_string_literal: true

class ChatReplySerializer
  include JSONAPI::Serializer

  set_type :messages

  set_id { SecureRandom.uuid }

  attribute :content do |object|
    object[:reply]
  end

  attribute :history do |object|
    object[:history]
  end

  meta do |object|
    {
      session_uuid: object[:session_uuid]
    }
  end
end
