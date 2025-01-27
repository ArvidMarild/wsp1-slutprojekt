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

    get '/loginlink' do
        erb :login
      end

    post '/login' do

    end
      
    get '/signuplink' do
      erb :signup
    end

    post '/singup' do
      puts "PARAMS: #{params.inspect}" # Log parameters for debugging

      if params["signup-password"] == params["signup-confirm-password"]
        db.execute("INSERT INTO users (email, username, password) VALUES(?,?,?)", 
        [   
            params["signup-email"],
            params["signup-name"],
            params["signup-password"]
        ])
        redirect "/"
      else
        erb :signupreject
      end
    end
end
