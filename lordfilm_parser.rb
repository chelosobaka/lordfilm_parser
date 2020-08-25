module ParserLordfilm
  require 'open-uri'
  require 'nokogiri'
  require 'net/http'
  require 'json'

  URL_LORDFILM = "http://f2.llordfilm.tv/"

  def parse_page(url_page)
    html = open(url_page)
    doc = Nokogiri::HTML(html)
    links_array = []
    doc.css('div.short div.short-in a').each{|x| links_array << "URL_LORDFILM" + x['href']}
    links_array
  end

  def parse_film(url)
    sleep 1
    html = open(url)
    doc = Nokogiri::HTML(html)

    kp_id = doc.css('iframe').first.attributes['src'].value.match(/\d+$/).to_s
    title_ru = doc.css('h2 span').first.text

      if doc.css('ul#s-list li').size > 5 #русские фильмы не имеют анг названия
        title_en = doc.css('ul#s-list li')[0].css('span')[1].text
        size = 4
      else
        size = 5
        title_en = nil
      end

    year = doc.css('ul#s-list li')[5-size].css('span')[1].text
    actors = doc.css('ul#s-list li')[6-size].css('span')[1].text.split(',').each{|w| w.lstrip!}
    producer = doc.css('ul#s-list li')[7-size].css('span')[1].text
    country = doc.css('ul#s-list li')[8-size].children[1].text.split(',').each{|w| w.lstrip!}
    genre =  doc.css('ul#s-list li')[9-size].css('span')[1].text.split(',').each{|w| w.lstrip!}
    about = doc.css('div#s-desc').text.strip
    poster = "http://u5.lordfilm7.tv#{doc.css('div.fposter img').first.attributes['src'].value}"

    puts "Movie: #{title_ru} complited."
    hash = {
      kp_id: kp_id,
      title_ru: title_ru,
      title_en: title_en,
      year: year,
      actors: actors,
      producer: producer,
      country: country,
      genre: genre,
      about: about,
      poster: poster
    }
  end



  def start(first_page, last_page)
    if first_page > last_page
      raise "The first parameter cannot be greater than the second."
    elsif first_page < 0 || last_page < 0
      raise "Parameter must be greater than 0."
    end

    (first_page..last_page).each do |page|
      parse_page("#{URL_LORDFILM}films/page/#{page}/").each do |url|
        begin
          hash_with_movie = parse_film(url)
        rescue NoMethodError => e
          puts "NoMethodError."
          next
        rescue => e
          puts e
          next
        end
        yield(hash_with_movie)
      end
      puts "Page #{page} completed."
      sleep 10
    end
  end

=begin
  def start_with_rails
    array_with_movies = []
    start do |hash_with_movie|
      array_with_movies << hash_with_movie
    end
    array_with_movies
  end

  def write_json(hash_with_movie, file_name = "lordfilm")
    File.open(file_name, "a") do |f|
      f.write(JSON.pretty_generate(hash_with_movie))
    end
    puts "Movie: #{hash_with_movie[:title_ru]} writed to json."
  end
=end

  def start_without_rails(file_name, first_page, last_page)
    File.open("#{file_name}.json", "a+") do |f|
      f.write("[\n")
      start(first_page, last_page) do |hash_with_movie|
        f.write("  ")
        f.write(JSON.pretty_generate(hash_with_movie))
        f.write(",\n")
        puts "Movie: #{hash_with_movie[:title_ru]} completed."
      end
        f.truncate(f.size - 2)
        f.write("\n]")
    end
  end
end

