class App < Sinatra::Base
    get '/' do
        erb(:"index")
    end

    def db
      return @db if @db

      @db = SQLite3::Database.new("db/beatsun.sqlite")
      @db.results_as_hash = true

      return @db
    end

    configure do
      enable :sessions
      set :session_secret, SecureRandom.hex(64)
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
      beats = db.execute("SELECT * FROM beats")
      erb :admin, locals: { username: user["username"], beats: beats}
    end    

    get '/uploads' do
      unless session[:user_id]
        redirect '/login'
      end
      # @upload = db.execute("SELECT * FROM users")
      erb :uploads
    end

    # get '/uploads/:id' do |id|
    #   @upload = db.execute("SELECT filepath FROM beats WHERE id = ?", id).first
    #   redirect '/admin'
    # end

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
        db.execute("INSERT INTO beats (artist, genre, key, bpm, filepath, name) VALUES(?,?,?,?,?,?)",
        [
          username,
          params["genre"],
          params["key"],
          params["bpm"],
          filepath,
          params["name"]
        ])
        redirect '/admin'
      else
        "No file selected!"
      end
    end

    get '/beats/:id/edit' do | id |
      @beats = db.execute('SELECT * FROM beats WHERE id = ?', id).first
      erb(:"edit")
    end

    get '/unauthorized' do
      erb :unauthorized
    end

    get '/logout' do
      p "/logout : Logging out"
      session.clear
      redirect '/'
    end

    post '/singup' do
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
          redirect "/"
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
  
      user = db.execute("SELECT *
              FROM users
              WHERE email = ?",
              request_email).first
  
      unless user
        p "/login : Invalid e-mail."
        status 401
        redirect '/unauthorized'
      end
  
      db_id = user["id"].to_i
      db_password_hashed = user["password"].to_s
  
      # Create a BCrypt object from the hashed password from db
      bcrypt_db_password = BCrypt::Password.new(db_password_hashed)
      # Check if the plain password matches the hashed password from db
      if bcrypt_db_password == request_plain_password
        p "/login : Logged in -> redirecting to admin"
        session[:user_id] = db_id
        redirect '/admin'
      else
        p "/login : Invalid password."
        status 401
        redirect '/unauthorized'
      end
    end
end
