class Event < ActiveRecord::Base
  
  attr_accessible :club, :date, :homepage, :lat, :lng, :name, :obhana_info_url, :obhana_register_url, :kind
  
  scope :future, lambda{ where('date >= ?', Date.today)}
  scope :with_location, where('lat > 0 AND lng > 0')
  scope :without_location, where('lat IS NULL OR lng IS NULL')
  
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
  
  def find!
    require 'open-uri'
    unless obhana_info_url.blank?
      doc = Nokogiri::HTML(open(obhana_info_url))
      doc.css("table > tr").each do |row|
        if row.css("td")[0].text.to_s.mb_chars.strip == 'Místo konání'
          place = row.css("td")[2].text.to_s.mb_chars.strip
          unless place.blank?
            puts "@? #{place}"
            res = Geokit::Geocoders::MultiGeocoder.geocode("#{place} , Czech Republic")
            if res and res.lat and res.lat > 0
              self.lat, self.lng = res.lat, res.lng
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
  
  def pair!
    e = Event.where(:date => date, :club => club)
    if (e.size == 2)
      [:homepage, :lat, :lng, :name, :obhana_info_url, :obhana_register_url].each do |a|
        a = a.to_s
        if e.first.attributes[a].blank? and !e.last.attributes[a].blank?
          e.first.update_attribute(a, e.last.attributes[a])
        end
      end
      puts "(merging #{e.first} and #{e.last}) ->\n   #{e.first}"
      e.last.destroy
    end
  end
  
end
