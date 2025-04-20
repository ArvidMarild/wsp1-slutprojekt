class User_beats
    def self.create(db, user_id, beat_id, date)
        db.execute("INSERT INTO user_beats (user_id, beat_id, date) VALUES (?,?,?)",
        [user_id, beat_id, date])
    end
end