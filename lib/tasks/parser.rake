namespace :events do

  task :build => [:clean, :fetch_hana, :fetch_klobouk, :find]
  
  task :clean => :environment do
    Event.destroy_all
  end
  
  task :find => :environment do
    Event.all.each do |e|
      e.find!
    end
  end
  
  
  task :fetch_klobouk  => :environment do
    require 'open-uri'
    url = "http://klobouk.fsv.cvut.cz/~hora/kalendar/kal2001.php?M=2&N=2"
    doc = Nokogiri::HTML(open(url))
    doc.css("table").each do |table|
      if (thx = table.css("tr>th").first) and thx.text.include?('Kdy')
        table.css('tr').each do |row|
          if row.css('td').size == 7
            cells = (0..6).map{|i| row.css("td")[i]}
            
            date = cells[0].text.to_s.mb_chars.strip.split(".")
            if date.size == 3
              d,m,y = date[0].to_i, date[1].to_i, date[2].to_i
              y += 2000 if y < 100
              date = Date.civil(y,m,d)
              name = cells[3].text.mb_chars.strip
              club = cells[5].text.mb_chars.strip
              
              lat, lng, hurl, rurl, purl = nil, nil, nil, nil, nil
              
              cells[6].css("a").each do |link|
                if img = link.css('img').first
                  src = img.attributes['src'].to_s.mb_chars
                  url = link.attributes['href'].to_s
                  if src.include?('globe')
                    if (url =~ /ssq=(\d+)°(\d+)'(\d+)\.(\d+)%22N, (\d+)°(\d+)'(\d+)\.(\d+)%22E@/)
                      a,b,c,d = $1.to_f, $2.to_f, $3.to_f, $4.to_f
                      e,f,g,h = $5.to_f, $6.to_f, $7.to_f, $8.to_f
                      lat = a + b/60 + c/3600 + d/3600000
                      lng = e + f/60 + g/3600 + h/3600000
                    end
                  elsif src.include?('rozpis')
                    rurl = url
                  elsif src.include?('pokyny')
                    purl = url
                  elsif src.include?('home')
                    hurl = url
                  end
                end
              end
              
              kind = 'OB'
              case row.attributes['bgcolor'].to_s.mb_chars.strip 
              when 'FFD0D0'
                kind = 'MTBO'
              when 'D0E0D0'
                kind = 'HOB'
              end

              puts "[#{date}][#{club}:#{name}] @ [#{lat},#{lng}] => [#{hurl}]"
              e = Event.create!(
              :name => name,
              :club => club,
              :date => date,
              :lat => lat, :lng => lng,
              :homepage => hurl,
              :rozpis_url => rurl,
              :pokyny_url => purl,
              :kind => kind
              )
              e.pair!
            end
          end          
        end
      end
    end
  end
  
  task :fetch_hana => :environment do
    require 'open-uri'
    url = "http://www.obhana.cz/prihlasky/VyberZavod.asp"
    doc = Nokogiri::HTML(open(url))
    doc.css("body > table")[1].css("tr").each do |row|
      
      cells = (0..7).map{|i| row.css("td")[i]}
      
      date = cells[1].text.to_s.mb_chars.strip.split(".")
      if date.size == 3
        d,m,y = date[0].to_i, date[1].to_i, date[2].to_i
        date = Date.civil(y,m,d)
        club = cells[2].text.mb_chars.strip
        name = cells[3].text.mb_chars.strip
      
        lat, lng = nil,nil
        if a = cells[4].css("a")[0]
          url =  a.attributes["href"].to_s.mb_chars.strip
          if url =~ %r{^http://www.mapy.cz/\?query=(\d+\.\d+)\s+(\d+\.\d+)$}
            x,y = url.split("=")            
            lat, lng = *y.split.map(&:to_f)
          else
            puts url
          end
        end

        rurl, iurl, hurl = nil, nil, nil
        if a = cells[0].css("a")[0]
          rurl = "http://www.obhana.cz/prihlasky/" + a.attributes["href"].to_s
        end
        if a = cells[3].css("a")[0]
          hurl = a.attributes["href"].to_s
        end
        if a = cells[7].css("a")[0]
          iurl = "http://www.obhana.cz/prihlasky/" + a.attributes["href"].to_s
        end

        puts "[#{date}][#{club}:#{name}][#{rurl}][#{iurl}] @ [#{lat},#{lng}] => [#{hurl}]"
        e = Event.create!(
        :name => name,
        :club => club,
        :date => date,
        :lat => lat, :lng => lng,
        :obhana_info_url => iurl,
        :obhana_register_url => rurl,
        :homepage => hurl,
        :kind => 'OB'
        )
        e.ob_hana!
        e.pair!
      else 
        puts "? [#{date}]"
      end
    end
  end
  
end