class ThreadRead < ApplicationRecord
  belongs_to :message_thread
  belongs_to :user
end
