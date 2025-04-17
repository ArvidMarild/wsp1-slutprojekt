class App < Sinatra::Base
  # Logging och inloggnings-skydd

  configure do
    enable :sessions
    set :session_secret, SecureRandom.hex(64)
    use Rack::Protection::AuthenticityToken
  end

  helpers do
    def db
      return @db if @db

      @db = SQLite3::Database.new("db/beatsun.sqlite")
      @db.results_as_hash = true

      return @db
    end
  end
  
    get '/' do
      @beats = db.execute("SELECT * FROM beats")
      erb(:"index")
    end

    get '/login' do
      erb :login
    end
      
    get '/signup' do
      erb :signup
    end

    get '/admin' do
      unless session[:user_id]
        redirect '/login'
      end
      user = db.execute("SELECT * FROM users WHERE id = ?", session[:user_id]).first
      @beats = db.execute("SELECT * FROM beats")
      erb :admin, locals: { username: user["username"]}
    end    

    get '/uploads' do
      unless session[:user_id]
        redirect '/login'
      end
      user = db.execute("SELECT * FROM users WHERE id = ?", session[:user_id]).first
      erb :uploads, locals: {username: user["username"]}
    end

    post '/uploads' do 
      if params[:file]
        filename = params[:file][:filename]
        file = params[:file][:tempfile]
        type = File.extname(filename)
        filepath = "/uploads/#{Time.now.to_i}#{type}"
        p file
        user = db.execute("SELECT * FROM users WHERE id = ?", session[:user_id].to_i).first
        username = user ? user["username"] : "Unknown"
    
        File.open("public/uploads/#{Time.now.to_i}#{type}", 'wb') do |f|
          f.write(file.read)
        end
        db.execute("INSERT INTO beats (artist, genre, key, bpm, filepath, name, price) VALUES(?,?,?,?,?,?,?)",
        [
          username,
          params["genre"],
          params["key"],
          params["bpm"],
          filepath,
          params["name"],
          params["price"]
        ])
        redirect '/admin'
      else
        "No file selected!"
      end
    end

    get '/beats' do
      p "beats"
      unless session[:user_id]
        redirect '/login'
      end
      @user = db.execute("SELECT * FROM users WHERE id = ?", session[:user_id]).first
      @beats = db.execute("SELECT * FROM beats")

      user_id = session[:user_id]

      # Get beat IDs purchased by this user
      beat_ids = db.execute("SELECT beat_id FROM user_beats WHERE user_id = ?", [user_id]).map { |row| row["beat_id"] }
    
      # Now get the beat details for those IDs
      if beat_ids.any?
        placeholders = beat_ids.map { '?' }.join(', ')
        purchased_beats = db.execute("SELECT * FROM beats WHERE id IN (#{placeholders})", beat_ids)
      else
        purchased_beats = []
      end

      @common = purchased_beats

      erb :beats
    end

    get '/beats/:id/edit' do | id |
      @beats = db.execute('SELECT * FROM beats WHERE id = ?', id).first
      erb(:"edit")
    end

    post '/beats/:id/update' do |id|
      p params
      p id
      db.execute("UPDATE beats SET genre=?, key=?, bpm=?, name=?, price=? WHERE id=?", 
        [
          params["genre"],
          params["key"],
          params["bpm"],
          params["name"],
          params["price"],
          id
        ])
      redirect '/admin'
    end
    

    post '/beats/:id/delete' do | id |
      db.execute('DELETE FROM beats WHERE id = ?', id)
      redirect "/admin"
    end

    get '/unauthorized' do
      erb :unauthorized
    end

    get '/logout' do
      p "/logout : Logging out"
      session.clear
      redirect '/'
    end

    post '/signup' do
      puts "PARAMS: #{params.inspect}" # Log parameters for debugging
      password_hashed = BCrypt::Password.create(params["password"])
      db_result = db.execute("SELECT * FROM users WHERE email = ?", [params[:email]])

      if db_result.length == 0
        if params[:password] == params[:confirm_password] 
          db.execute("INSERT INTO users (email, username, password) VALUES(?,?,?)", 
          [   
              params["email"],
              params["name"],
              password_hashed
          ])
          redirect "/admin"
        else
          p params[:password]
          p params[:confirm_password]
          "Different passwords"
        end
      else
        "Email already exists"
      end
    end   

    post '/login' do
      request_email = params[:email]
      request_plain_password = params[:password]
      ip = request.ip
      user = db.execute("SELECT * FROM users WHERE email = ?", request_email).first

      attempts = db.execute("SELECT COUNT(*) as count FROM login_log WHERE ip = ? AND success = 0 AND time > ?", [ip, Time.now.to_i - 60]).first
      if attempts["count"] >= 5
        halt 429, "För många inloggningsförsök. Försök igen om en stund."
      end
  
      unless user
        db.execute('INSERT INTO login_log (time, email, ip, success) VALUES(?,?,?,?)', 
          [
            Time.now.to_i,
            request_email,
            ip,
            0
          ])
        redirect '/unauthorized'
      end
  
      db_password_hashed = user["password"]
      if BCrypt::Password.new(db_password_hashed) == request_plain_password
        session[:user_id] = user["id"]
        db.execute('INSERT INTO login_log (time, email, ip, success) VALUES(?,?,?,?)', 
          [
            Time.now.to_i,
            request_email,
            ip,
            1
          ])
        redirect '/admin'
      else
        db.execute('INSERT INTO login_log (time, email, ip, success) VALUES(?,?,?,?)', 
          [
            Time.now.to_i,
            request_email,
            ip,
            0
          ])
        redirect '/unauthorized'
      end
    end   

    get '/shop' do
      @beats = db.execute("SELECT * FROM beats")
      erb :shop
    end

    post '/purchase/:id' do | id |
      unless session[:user_id]
        redirect '/login'
      end

      db.execute("INSERT INTO user_beats (user_id, beat_id, date) VALUES (?, ?, ?)", [session[:user_id], id, Time.now.to_i])

      redirect '/admin'
    end
end
