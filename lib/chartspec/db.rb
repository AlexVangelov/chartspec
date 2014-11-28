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
      @db.execute( "CREATE TABLE IF NOT EXISTS specs(id INTEGER PRIMARY KEY, file TEXT, chart TEXT, name TEXT, duration NUMERIC, measured_at DATETIME);" )
    end
    
    def add(file, chart, name, duration, measured_at = Time.now.to_i)
      @db.execute("INSERT INTO specs(file, chart, name, duration, measured_at) VALUES (?, ?, ?, ?, ?)", [
        file, chart.to_s, name, duration, measured_at
      ]) 
    end
    
    def select_by_file_and_chart(file, chart)
      @db.execute( "select name, duration, measured_at from specs where file = ? and chart = ? and measured_at > ?", [
        file, chart.to_s, (Time.now - ((ENV['CHARTSPEC_HISTORY_HOURS'] || 8)*3600)).to_i
      ])
    end
    
    def file_name
      @db_file
    end
  end
end