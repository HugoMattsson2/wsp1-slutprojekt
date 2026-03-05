require 'sqlite3'
require_relative '../config'

class Seeder

  def self.seed!
    puts "Using db file: #{DB_PATH}"
    puts "🧹 Dropping old tables..."
    drop_tables
    puts "🧱 Creating tables..."
    create_tables
    puts "🍎 Populating tables..."
    populate_tables
    puts "✅ Done seeding the database!"
  end


  def self.drop_tables
    db.execute('DROP TABLE IF EXISTS cookies')
    db.execute('DROP TABLE IF EXISTS customers')
  end

  def self.create_tables
    db.execute('CREATE TABLE cookies (
                cookieid INTEGER PRIMARY KEY AUTOINCREMENT,
                cookiename TEXT NOT NULL,
                cookiedescription TEXT,
                cookieprice TEXT)')

    db.execute('CREATE TABLE customers (
                customerid INTEGER PRIMARY KEY AUTOINCREMENT,
                customername TEXT NOT NULL,
                customerdescription TEXT,
                customerhistory TEXT)')
  end


  def self.populate_tables
    db.execute('INSERT INTO cookies (cookiename, cookiedescription, cookieprice) VALUES ("Choklad", " God med 25% protein", "25kr")')
    db.execute('INSERT INTO cookies (cookiename, cookiedescription, cookieprice) VALUES ("Vanilj", " God med 55% protein", "35kr")')
    db.execute('INSERT INTO customers (customername, customerdescription, customerhistory) VALUES ("Kevin", "170 cm", "4 kakor")')
  
  end



  private

  def self.db
    @db ||= begin
      db = SQLite3::Database.new(DB_PATH)
      db.results_as_hash = true
      db
    end
  end



end

Seeder.seed!