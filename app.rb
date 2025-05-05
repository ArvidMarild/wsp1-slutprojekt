class App < Sinatra::Base
  require_relative './models/user'
  require_relative './models/beat'
  require_relative './models/login_log'
  require_relative './models/user_beats'

  configure do
    enable :sessions
    set :session_secret, SecureRandom.hex(64)
    use Rack::MethodOverride
    use Rack::Protection::AuthenticityToken
  end

  helpers do
    # Hämtar eller initierar databasanslutningen
    #
    # @return [SQLite3::Database] databasanslutning
    def db
      return @db if @db
      @db = SQLite3::Database.new("db/beatsun.sqlite")
      @db.results_as_hash = true
      return @db
    end

    # Extraherar säkra parametrar från ett sign-up-formulär
    #
    # @param params [Hash] inkommande request-parametrar
    # @return [Hash] filtrerade parametrar
    def permitted_signup_params(params)
      {
        email: params["email"],
        name: params["name"],
        password: params["password"],
        confirm_password: params["confirm_password"]
      }
    end

    # Returnerar den nu inloggade användaren
    #
    # @return [Hash, nil] användarens databasrad eller nil om inte inloggad
    def current_user
      return nil unless session[:user_id]
      User.find_by_id(db, session[:user_id])
    end

    # Kontrollerar om aktuell användare är admin
    #
    # @return [Boolean] true om admin, annars false
    def admin?
      user = current_user
      user && user["admin"].to_i == 1
    end
  end

  ## ROUTER ##
  
  # Start-/hemsidan
  get '/' do
    @beats = Beat.all(db)
    erb :index
  end

  # Login-formulär
  get '/login' do
    erb :login
  end

  # Signup-formulär
  get '/signup' do
    erb :'users/new'
  end

  # Adminpanel, kräver inloggning
  get '/admin' do
    redirect '/login' unless current_user
    @beats = Beat.all(db)
    erb :admin, locals: { username: current_user["username"] }
  end

  # Visa alla beats
  get '/beats' do
    @beats = Beat.all(db)
    erb :'beats/index'
  end

  # Formulär för att ladda upp ett nytt beat
  get '/beats/new' do
    redirect '/login' unless current_user
    erb :'beats/new', locals: { username: current_user["username"] }
  end

  # Skapar ett nytt beat
  #
  # @return [Redirect] till admin-sidan
  post '/beats' do
    halt 400, "No file selected!" unless params[:file]

    filename = params[:file][:filename]
    file = params[:file][:tempfile]
    type = File.extname(filename)
    filepath = "/uploads/#{Time.now.to_i}#{type}"

    File.open("public#{filepath}", 'wb') { |f| f.write(file.read) }

    Beat.create(db, current_user["username"], params["genre"], params["key"], params["bpm"], filepath, params["name"], params["price"])
    redirect '/admin'
  end

  # Visar ett enskilt beat (kräver inloggning)
  get '/beats/:id' do
    redirect '/login' unless current_user
    @user = current_user
    @beats = Beat.all(db)
    @common = Beat.purchased_by_user(db, session[:user_id])
    erb :'beats/show'
  end

  # Redigerar ett beat
  #
  # @param id [String] ID för beatet
  get '/beats/:id/edit' do |id|
    @beats = Beat.find_by_id(db, id)
    erb :'beats/edit'
  end

  # Uppdaterar ett beat
  #
  # @param id [String] ID för beatet
  put '/beats/:id' do |id|
    Beat.update(db, id, params["genre"], params["key"], params["bpm"], params["name"], params["price"])
    redirect '/admin'
  end

  # Tar bort ett beat
  #
  # @param id [String] ID för beatet
  delete '/beats/:id' do |id|
    Beat.delete(db, id)
    redirect '/admin'
  end

  # Skapar en köprelation mellan användare och beat
  #
  # @param id [String] ID för beatet
  post '/beats/:id' do |id|
    redirect '/login' unless current_user
    User_beats.create(db, session[:user_id], id, Time.now.to_i)
    redirect '/admin'
  end

  # Visar unauthorized-sidan
  get '/unauthorized' do
    erb :unauthorized
  end

  # Loggar ut användaren
  post '/logout' do
    session.clear
    redirect '/'
  end

  # Skapar ny användare
  post '/users/new' do
    safe_params = permitted_signup_params(params)
    if safe_params[:password] == safe_params[:confirm_password]
      existing_user = User.find_by_email(db, safe_params[:email])
      if existing_user
        "Email already exists"
      else
        User.create(db, safe_params[:email], safe_params[:name], safe_params[:password])
        redirect '/admin'
      end
    else
      "Different passwords"
    end
  end

  # Hanterar login
  post '/login' do
    request_email = params[:email]
    request_plain_password = params[:password]
    ip = request.ip

    attempts = Login_log.count(db, ip, Time.now.to_i)
    halt 429, "För många inloggningsförsök. Försök igen om en stund." if attempts["count"] >= 5

    user = User.authenticate(db, request_email, request_plain_password)

    if user
      session[:user_id] = user["id"]
      Login_log.create(db, Time.now.to_i, request_email, ip, 1)
      redirect '/admin'
    else
      Login_log.create(db, Time.now.to_i, request_email, ip, 0)
      redirect '/unauthorized'
    end
  end

  # hanterar köpordrar och lägger dem i databasen
  post '/beats/purchase/:id' do |id|
    redirect '/login' unless current_user
    User_beats.create(db, session[:user_id], id, Time.now.to_i)
    redirect '/admin'
  end
end