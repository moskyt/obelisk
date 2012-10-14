class Event < ActiveRecord::Base

  attr_accessible :club, :date, :homepage, :lat, :lng, :name, :obhana_info_url, :obhana_register_url, :pokyny_url, :rozpis_url, :kind, :place

  scope :future, lambda{ where('date >= ?', Date.today).order(:date)}
  scope :this_week, lambda{ where('date <= ?', Date.today.end_of_week).order(:date)}
  scope :next_week, lambda{ where('date > ? AND date <= ?', Date.today.end_of_week, Date.today.end_of_week+1.week).order(:date)}
  scope :superfuture, lambda{ where('date >= ?', Date.today.end_of_week+1.week).order(:date)}
  scope :with_location, where('(lat > 0) AND (lng > 0)')
  scope :without_location, where('lat IS NULL OR lng IS NULL')

  def self.location_grouped(events)
    #return events.map{|e| [e]}
    list = []
    events = events.to_a.dup
    n0 = events.size
    while events.size > 0
      e = [events.first]
      events = events[1..-1]
      events.each do |ee|
        if (ee.lat - e.first.lat).abs + (ee.lng - e.first.lng).abs < 0.0001
          e << ee
          events = events - [ee]
        end
      end
      if e.size > 1
        puts "!#{e.map(&:to_s)} * '+'}"
      end
      list << e
    end
    puts "#{n0} -> #{list.size}"
    list
  end

  def letter
    case kind
    when 'OB'
      'P'
    when 'LOB'
      'L'
    when 'NOB'
      'N'
    when 'HOB'
      'H'
    when 'MTBO'
      'B'
    else
      'X'
    end
  end

  def to_s
    "[#{date}][#{club}:#{kind} -- #{name}] @ [#{lat},#{lng}] => [#{homepage}]"
  end

  def color
    if date <= Date.today.end_of_week
      'red'
    elsif date <= Date.today.end_of_week + 1.week
      'yellow'
    else
      'paleblue'
    end
  end

  def urls
    {
      'homepage' => homepage,
      'rozpis' => rozpis_url,
      'pokyny' => pokyny_url,
    }.select{|x,y| !y.blank?}
  end

  def find!
    require 'open-uri'
    unless obhana_info_url.blank?
      doc = Nokogiri::HTML(open(obhana_info_url))
      doc.css("table > tr").each do |row|
        if row.css("td")[0].text.to_s.mb_chars.strip == 'Místo konání'
          place = row.css("td")[2].text.to_s.mb_chars.gsub('mapy.cz','').strip
          unless place.blank?
            puts "@? #{place}"
            self.place = place
            self.save!
            unless lat and lng and lat>0 and lng>0
              res = Geokit::Geocoders::MultiGeocoder.geocode("#{place} , Czech Republic")
              if res and res.lat and res.lat > 0
                self.lat, self.lng = res.lat.to_f, res.lng.to_f
                self.save!
                puts "  -> #{self}"
              else
                puts "Not found"
              end
            end
          end
        end
      end
    end
  end

  def pair!
    e = Event.where(:date => date, :club => club)
    if (e.size == 2)
      [:homepage, :rozpis_url, :pokyny_url, :name, :obhana_info_url, :obhana_register_url].each do |a|
        a = a.to_s
        if e.first.attributes[a].blank? and !e.last.attributes[a].blank?
          e.first.update_attribute(a, e.last.attributes[a])
        end
      end
      [:lat, :lng].each do |a|
        a = a.to_s
        if !(e.first.attributes[a] and e.first.attributes[a] > 0) and (e.last.attributes[a] and e.last.attributes[a] > 0)
          e.first.update_attribute(a, e.last.attributes[a])
        end
      end
      puts "(merging #{e.first} and #{e.last}) ->\n   #{e.first}"
      e.last.destroy
    end
  end

end
