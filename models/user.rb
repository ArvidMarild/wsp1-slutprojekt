require 'bcrypt'

class User
  def self.find_by_email(db, email)
    db.execute("SELECT * FROM users WHERE email = ?", [email]).first
  end

  def self.find_by_id(db, id)
    db.execute("SELECT * FROM users WHERE id = ?", [id]).first
  end

  def self.create(db, email, username, password)
    hashed = BCrypt::Password.create(password)
    db.execute("INSERT INTO users (email, username, password) VALUES (?, ?, ?)", [email, username, hashed])
  end

  def self.authenticate(db, email, password)
    user = find_by_email(db, email)
    return nil unless user
    return user if BCrypt::Password.new(user["password"]) == password
    nil
  end
end
