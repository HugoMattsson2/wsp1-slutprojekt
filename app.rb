require 'debug'
require "awesome_print"

class App < Sinatra::Base

    setup_development_features(self)

    # Funktion för att prata med databasen
    # Exempel på användning: db.execute('SELECT * FROM fruits')
    def db
      return @db if @db
      @db = SQLite3::Database.new(DB_PATH)
      @db.results_as_hash = true

      return @db
    end

    # Routen /
    get '/' do
       redirect("/index")
    end

    get '/index' do
      @cookies = db.execute('SELECT * FROM cookies')
      @customers = db.execute('SELECT * FROM customers')

      erb(:"/index")
    end

    get '/products' do
      @cookies = db.execute('SELECT * FROM cookies')
      @customers = db.execute('SELECT * FROM customers')

      erb(:"/products")
    end

    get '/products/:cookieid' do | cookieid |
      @cookies = db.execute('SELECT * FROM cookies WHERE cookieid=?', cookieid).first
     

      erb(:"/show")
    end



    

end
