class AccessLog < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :lock
  # belongs_to :card, foreign_key: :card_number, optional: true

  enum direction: {
      enter: 'enter',
      exit: 'exit'
  }

  def self.recent_logs_for_user(user, count)
    AccessLog.where(user_id: user.id).order(:created_at).reverse_order.limit(count)
  end

  def self.recent_logs_for_card_number(card_number, count)
    AccessLog.where(card_number: card_number).order(:created_at).reverse_order.limit(count)
  end

  def self.recent_logs_for_lock(lock, count)
    AccessLog.where(lock_id: lock.id).order(:created_at).reverse_order.limit(count)
  end

  def self.latest_for_users_currently_behind(lock)
    AccessLog.where('user_id is not null').where(lock_id: lock.id).group('user_id').having('MAX(ROWID)').order('ROWID').to_a
  end
end
