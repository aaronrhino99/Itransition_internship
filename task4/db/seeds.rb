require "json"

digest = Devise::Encryptor.digest(User, SecureRandom.hex(16))

rows = JSON.parse(File.read(Rails.root.join("db/users.json"))).map do |u|
  {
    name: u["full_name"],
    email: u["email"].downcase,
    job_position: u["job_position"],
    status: u["status"],
    current_sign_in_at: u["last_seen"],
    encrypted_password: digest
  }
end

User.upsert_all(rows, unique_by: :email)
puts "Users: #{User.count} #{User.group(:status).count}"