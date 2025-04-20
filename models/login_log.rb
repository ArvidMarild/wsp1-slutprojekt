class Login_log
    def self.create(db, time, email, ip, success)
      db.execute('INSERT INTO login_log (time, email, ip, success) VALUES(?,?,?,?)', 
                 [time, email, ip, success])
    end
  
    def self.count(db, ip, time)
      db.execute("SELECT COUNT(*) as count FROM login_log WHERE ip = ? AND success = 0 AND time > ?", 
                 [ip, time - 60]).first
    end
end
  