class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  enum :status, { active: "active", blocked: "blocked" }, default: "active"
  validates :name, presence: true

  def active_for_authentication?
    super && active?
  end

  def inactive_message
    blocked? ? :blocked : super
  end
end
