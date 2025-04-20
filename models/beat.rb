class Beat
    def self.all(db)
      db.execute("SELECT * FROM beats")
    end
  
    def self.find_by_id(db, id)
      db.execute("SELECT * FROM beats WHERE id = ?", [id]).first
    end
  
    def self.create(db, artist, genre, key, bpm, filepath, name, price)
      db.execute("INSERT INTO beats (artist, genre, key, bpm, filepath, name, price) VALUES (?, ?, ?, ?, ?, ?, ?)",
                  [artist, genre, key, bpm, filepath, name, price])
    end
  
    def self.update(db, id, genre, key, bpm, name, price)
      db.execute("UPDATE beats SET genre = ?, key = ?, bpm = ?, name = ?, price = ? WHERE id = ?",
                  [genre, key, bpm, name, price, id])
    end
  
    def self.delete(db, id)
      db.execute("DELETE FROM beats WHERE id = ?", [id])
    end
  
    def self.purchased_by_user(db, user_id)
      beat_ids = db.execute("SELECT beat_id FROM user_beats WHERE user_id = ?", [user_id]).map { |row| row["beat_id"] }
      return [] if beat_ids.empty?
      placeholders = beat_ids.map { '?' }.join(', ')
      db.execute("SELECT * FROM beats WHERE id IN (#{placeholders})", beat_ids)
    end
  end
  