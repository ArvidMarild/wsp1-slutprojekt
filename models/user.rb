class User
    def self.find_by_email(db, email)
      db.execute("SELECT * FROM users WHERE email = ?", [email]).first
    end
  
    def self.create(db, email, name, password)
      password_hashed = BCrypt::Password.create(password)
      db.execute("INSERT INTO users (email, username, password, admin) VALUES (?, ?, ?, ?)",
                 [email, name, password_hashed, 0])
    end
  
    def self.find_by_id(db, id)
      db.execute("SELECT * FROM users WHERE id = ?", [id]).first
    end
  end
  