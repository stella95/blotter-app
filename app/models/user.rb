class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :validatable,
         :lockable, :trackable, :timeoutable

  has_many :portfolios, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :entries, through: :portfolios

  validates :time_zone, presence: true,
                        inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }

  PASSWORD_COMPLEXITY = /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9])/
  validate :password_complexity

  def today
    (Time.find_zone(time_zone) || Time.zone).today
  end

  def short_name
    return if first_name.blank?
    return first_name if last_name.blank?

    "#{first_name} #{last_name.first}."
  end

  private

  def password_complexity
    return if password.blank?
    return if password.match?(PASSWORD_COMPLEXITY)

    errors.add(:password, :complexity)
  end
end
