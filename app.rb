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
      erb :admin
    end

    get '/upload' do
      erb :upload
    end

    post '/upload' do
      if params[:file]
        filename = params[:file][:filename]
        tempfile = params[:file][:tempfile]
        ext = File.extname(filename).downcase
        
        if %w[.mp3 .wav].include?(ext)
          filepath = File.join(UPLOADS_DIR, filename)
          File.open(filepath, 'wb') do |file|
            file.write(tempfile.read)
          end
          @message = "File uploaded successfully!"
        else
          @message = "Invalid file type. Only MP3 and WAV are allowed."
        end
      else
        @message = "No file selected."
      end
      erb :upload
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

      if params["signup-password"] == params["signup-confirm-password"]
        db.execute("INSERT INTO users (email, username, password) VALUES(?,?,?)", 
        [   
            params["email"],
            params["name"],
            password_hashed
        ])
        redirect "/"
      else
        erb :signupreject
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
