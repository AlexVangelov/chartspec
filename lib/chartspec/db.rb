require 'sqlite3'

module Chartspec
  class Db
    def initialize db = nil
      @db_file = db || "tmp/chartspec.sqlite3"
      db_dirname = File.dirname(@db_file)
      unless File.directory?(db_dirname)
        FileUtils.mkdir_p(db_dirname)
      end
      @db = SQLite3::Database.new @db_file
      @db.execute( "CREATE TABLE IF NOT EXISTS specs(id INTEGER PRIMARY KEY, file TEXT, name TEXT, duration NUMERIC, measured_at DATETIME);" )
    end
    
    def add(file, name, duration, measured_at = Time.now.to_i)
      @db.execute("INSERT INTO specs(file, name, duration, measured_at) VALUES (?, ?, ?, ?)", [
        file, name, duration, measured_at
      ]) 
    end
    
    def all
      @db.execute( "select file, name, duration, measured_at from specs where measured_at > ?", (Time.now - ((ENV['CHARTSPEC_HISTORY_HOURS'] || 2)*3600)).to_i)
    end
    
    def file_name
      @db_file
    end
  end
end