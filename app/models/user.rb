class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :portfolios, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :entries, through: :portfolios

  validates :time_zone, presence: true,
                        inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }

  def today
    (Time.find_zone(time_zone) || Time.zone).today
  end
end
