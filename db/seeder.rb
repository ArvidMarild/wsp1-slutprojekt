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
  end

  def self.create_tables
    db.execute('CREATE TABLE users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                email TEXT NOT NULL,
                username TEXT NOT NULL,
                password TEXT NOT NULL)')
    db.execute('CREATE TABLE beats (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                genre TEXT NOT NULL,
                key TEXT NOT NULL,
                bpm INTEGER NOT NULL)')
  end

  def self.populate_tables
    password_hashed = BCrypt::Password.create('arvid12345')
    p "Storing hashed version of password to db. Clear text never saved. #{password_hashed}"
    db.execute('INSERT INTO users (email, username, password) VALUES (?, ?, ?)', ['arvid.marild@gmail.com', 'arvid', password_hashed])
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