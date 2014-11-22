class User < ActiveRecord::Base
	has_many :clouds, dependent: :destroy
  has_many :platforms, dependent: :destroy
  has_many :demos, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :regexpressions, dependent: :destroy
	attr_accessible :email, :password, :password_confirmation

  attr_accessor :password
  before_save :encrypt_password

  validates_confirmation_of :password
  validates_presence_of :password, :on => :create
  validates_presence_of :email
  validates_uniqueness_of :email

	# Authenticate a user
  def self.authenticate(email, password)
    user = find_by_email(email)
    if user && user.password_hash == BCrypt::Engine.hash_secret(password, user.password_salt)
      user
    else
      nil
    end
  end

	# Encrypt the user's password
  def encrypt_password
    if password.present?
      self.password_salt = BCrypt::Engine.generate_salt
      self.password_hash = BCrypt::Engine.hash_secret(password, password_salt)
    end
  end
end
