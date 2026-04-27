require 'debug'
require "awesome_print"
require "bcrypt"


class App < Sinatra::Base
  enable :sessions

  set :session_secret, "en_super_lång_secret_som_är_minst_64_tecken_lång_1234567890abcdef"

 set :protection, except: :http_origin

    setup_development_features(self)

    # Funktion för att prata med databasen
    # Exempel på användning: db.execute('SELECT * FROM fruits')
    def db
      return @db if @db
      @db = SQLite3::Database.new(DB_PATH)
      @db.results_as_hash = true

      return @db
    end

    def require_login
      unless session[:user_id]
        redirect('/login')
      end
    end

    before do
      puts "SESSION: #{session.inspect}"

      if session[:user_id]
        @customer = db.execute(
          "SELECT * FROM customers WHERE customerid = ?",[session[:user_id]]).first

    puts "CUSTOMER: #{@customer}"
      end
    end
  
    helpers do
      def current_user
        return nil unless session[:user_id]
        @current_user ||= db.execute(
          "SELECT * FROM customers WHERE customerid = ?",
          session[:user_id]
        ).first
      end
    
      def admin?
        current_user && current_user["role"] == "admin"
      end
    end


    # Routen /
    get '/' do
       redirect("/main/index")
    end

    get '/main/index' do
      @cookies = db.execute('SELECT * FROM cookies')
      @customers = db.execute('SELECT * FROM customers')
      session[:cart] = {} unless session[:cart].is_a?(Hash)

      @cart_items = session[:cart_items] || {} 


      erb(:"/main/index")
    end

    get '/products' do
      @cookies = db.execute('SELECT * FROM cookies')
      @customers = db.execute('SELECT * FROM customers')

      erb(:"/products/products")
    end




    get '/products/new' do

      erb(:"/products/new")
    end

    post '/products' do

      halt 403, "Not allowed" unless admin?

      cname = params["cookiename"]
      cdesc = params["cookiedescription"]
      cprice = params["cookieprice"]

      db.execute("INSERT INTO cookies (cookiename, cookiedescription, cookieprice) VALUES (?, ?, ?)", [cname, cdesc, cprice])

      redirect('/products')
    end


    
    post '/products/:cookieid/delete' do | cookieid |

      halt 403, "Not allowed" unless admin?

      db.execute("DELETE FROM cookies WHERE cookieid=?", cookieid)
      redirect("/products")

    end

    get '/products/:cookieid' do | cookieid |
      @cookie = db.execute('SELECT * FROM cookies WHERE cookieid=?', cookieid).first
     

      erb(:"/products/show")
    end

    get '/products/:cookieid/edit' do | cookieid |

      @cookies = db.execute('SELECT * FROM cookies WHERE cookieid=?', cookieid).first

      erb(:"/products/edit")
    end

    post "/products/:cookieid/update" do | cookieid |
      halt 403, "Not allowed" unless admin?

      newcname = params["newcookiename"]
      newcdesc = params["newcookiedescription"]
      newcprice = params["newcookieprice"]

      db.execute("UPDATE cookies SET cookiename=?, cookiedescription=?, cookieprice=? WHERE cookieid=?", [newcname, newcdesc, newcprice, cookieid])

      redirect('/products')
    end



  get '/login' do

    erb(:"/user/login")
  end

  get '/signup' do

    erb(:"/user/signup")

  end

  get '/logout' do
    session.clear
    redirect('/main/index')
  end

  post '/signup' do

    uname = params["customername"]
    upass = params["customerpass"]
    upass_encrypted = BCrypt::Password.create(upass)

    begin
      db.execute("INSERT INTO customers (customername, customerpass) VALUES (?, ?)", [uname, upass_encrypted])

      user = db.execute(
        "SELECT * FROM customers WHERE customername = ?",
        [uname]
      ).first
    
      session[:user_id] = user["customerid"]
    

      redirect('/main/index')

    rescue SQLite3::ConstraintException
      @error = "Användarnamnet finns redan"
      erb(:"/user/signup")
    end
  end


  post '/login' do

    uname = params["customername"]
    upass = params["customerpass"]
   
    puts "uname: '#{uname}'"
  

    user = db.execute("SELECT * FROM customers WHERE customername=?", [uname]).first
      

ap db.execute("SELECT * FROM customers")

        if user.nil?
          @error = "Användaren finns inte"
          return erb(:"/user/login")
        end

        if  BCrypt::Password.new(user["customerpass"]) == upass
          session[:user_id] = user["customerid"]

          puts "LOGIN SUCCESS: #{session[:user_id]}"
 
          redirect('/main/index')
        else
          @error = "Fel lösenord"
          erb(:"/user/login")
        end
  end 

  get "/cart" do
    session[:cart] ||= {}
    session[:cart] = {} unless session[:cart].is_a?(Hash)
  
    @cart_items = session[:cart].map do |id, qty|
      cookie = db.execute("SELECT * FROM cookies WHERE cookieid = ?", id).first
      next unless cookie
  
      cookie["quantity"] = qty
      cookie
    end.compact
  
    erb :"cart/cartindex"
  end


  post "/cart/add/:id" do
    id = params[:id].to_s
    qty = params[:quantity].to_i
    qty = 1 if qty <= 0
  
    session[:cart] ||= {}
    session[:cart][id] ||= 0
    session[:cart][id] += qty
  
    redirect "/cart"
  end

  post "/cart/remove_one/:id" do
    id = params[:id].to_s
    session[:cart][id] ||= 0
  
    if session[:cart][id]
      session[:cart][params[:id]] -= 1
    end
  
    redirect "/cart"
  end
end
