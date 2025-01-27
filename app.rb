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

    get '/login' do
      erb :login
    end
      
    get '/signup' do
      erb :signup
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
end
