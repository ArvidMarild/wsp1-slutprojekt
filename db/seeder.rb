require 'sqlite3'
require 'bcrypt'

class Seeder

  def self.seed!
    drop_tables
    create_tables
    populate_tables
  end

  def self.drop_tables
    db.execute('DROP TABLE IF EXISTS users')
    db.execute('DROP TABLE IF EXISTS beats')
    db.execute('DROP TABLE IF EXISTS user_beats')
    db.execute('DROP TABLE IF EXISTS login_log')
  end

  def self.create_tables
    db.execute('CREATE TABLE users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                email TEXT NOT NULL,
                username TEXT NOT NULL,
                password TEXT NOT NULL,
                admin INTEGER DEFAULT 0)')
    db.execute('CREATE TABLE beats (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                artist NOT NULL,
                genre TEXT NOT NULL,
                key TEXT NOT NULL,
                bpm INTEGER NOT NULL,
                filepath NOT NULL,
                name TEXT NOT NULL,
                price INTEGER NOT NULL)')
    db.execute('CREATE TABLE user_beats (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER,
                beat_id INTEGER,
                date INTEGER)')
    db.execute('CREATE TABLE login_log (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                time INTEGER NOT NULL,
                email TEXT NOT NULL,
                ip TEXT,
                success BOOL NOT NULL)')
  end

  def self.populate_tables
    password_hashed = BCrypt::Password.create('arvid12345')
    db.execute('INSERT INTO users (email, username, password, admin) VALUES (?,?,?,?)', ['arvid.marild@gmail.com', 'Arvid Mårild', password_hashed, 1])
  end

  private
  def self.db
    return @db if @db
    @db = SQLite3::Database.new('db/beatsun.sqlite')
    @db.results_as_hash = true
    @db
  end
end

Seeder.seed!