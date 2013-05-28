class Term
  attr_accessor :term_id, :name, :status, :start_date, :end_date, :season, :acad_year

  def <=>(other)
    self.term_id <=> other.term_id
  end



  def to_s
    self.term_id.to_s
  end


  def Term.import_xml(terms_xml,curricular_year)
    @terms = Hash.new
    #puts curricular_year
    terms_xml.xpath("//row").each do |term_xml|
      #puts term_xml
      acad_year = term_xml.xpath("./acad_year").text.to_i
      start_date = Time.parse term_xml.xpath("./start_date").text
      #puts acad_year
      #puts acad_year.class
      if acad_year > 2012 && acad_year < curricular_year + 2
        #puts "importing #{acad_year} as it is less than #{ curricular_year + 2}"
        term = Term.new
        term.term_id = term_xml.xpath("./term_code").text.to_i
        term.acad_year = term_xml.xpath("./acad_year").text.to_i
        term.name = term_xml.xpath("./description").text
        term.season = term_xml.xpath("./season").text
        term.status = 'active'
        term.start_date = Time.parse term_xml.xpath("./start_date").text
        term.end_date = Time.parse term_xml.xpath("./end_date").text
        @terms[term.term_id] = term
      end
    end
    @terms
  end



  def Term.current_term?
    self.start_date < DateTime.now && self.end_date > DateTime.now

  end


  def weeks
    weeks =[]
    self.start_date.to_date.step(self.end_date.to_date, 7) { |date| weeks << date }
    weeks
  end


  def calendar_year()
    self.start_date.year
  end
  def Term.calendar_year(term)
    term.calendar_year
  end

  def curricular_year
    /(\d\d)(\d\d)/ =~ self.acad_year.to_s
    (Regexp.last_match(2).to_i - 1)*100 + Regexp.last_match(2).to_i
  end

  def acad_year_short
    acad_year - 2000
  end

  def acad_year_display
    "#{self.acad_year-1}-#{self.acad_year}"
  end

  def Term.acad_year_display(term)
    term.acad_year_display
  end

  def acad_year_display_short
    "#{self.acad_year_short-1}#{self.acad_year_short}"
  end
  def Term.acad_year_display_short(term)
    term.acad_year_display_short
  end


  def fall?()
    self.season.eql? 'Fall'
  end

  def winter?()
    self.season.eql? 'Winter'
  end

  def spring?()
    self.season.eql? 'Spring'
  end

  def summer?()
    self.season.eql? 'Summer'
  end


end