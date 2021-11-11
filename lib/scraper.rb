module Scraper

  def self.run (log_file)
    log_file.puts "   Scraper.run: start"
    config = TeSS::Config.ingestion
    log_file.puts "      ingestion file = #{config[:name]}"
    log_file.puts "   Scraper.run: finish"
  end


end