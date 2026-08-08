class Portfolio < ApplicationRecord
  belongs_to :user

  has_many :entries, dependent: :destroy
  has_many :entry_line_items, through: :entries
  has_many :portfolio_snapshots, dependent: :destroy

  normalizes :currency, with: ->(value) { value.to_s.strip.upcase }

  validates :name, presence: true,
                   uniqueness: { scope: :user_id, case_sensitive: false }
  validates :currency, presence: true, format: { with: /\A[A-Z]{3}\z/ }

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  def archived?
    archived_at.present?
  end

  def archive!
    update!(archived_at: Time.current)
  end
end
