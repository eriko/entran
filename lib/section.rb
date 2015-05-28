class Section
  attr_accessor :section_id, :course_id, :name, :status,
                :start_date, :end_date, :term_code ,:control,
                :current, :kind,:offering_codes

  def to_s
    "#{section_id} #{course_id} #{name} #{status} #{start_date} #{end_date}"
  end


  def Section.import_xml(lms_courses_xml, kind)
    #The courses to be used are from presence where the course site has been marked requested.
    #Then data from other data sources like the ims.xml feed will be used to gather the full set of data
    #based on the list from presence
    @sections = Hash.new

    #binding.pry
    lms_courses_xml.xpath("//website[type='#{kind}']/sections/section").each do |section_xml|

      section = Section.new
      section.section_id = section_xml.xpath("./@section_id").text
      section.course_id = section_xml.xpath("./@course_id").text
      section.name = section_xml.xpath("./@name").text
      section.control = section_xml.xpath("./@control").text
      section.kind = section_xml.xpath("./@kind").text
      section.current = section_xml.xpath("./@current").text.to_bool

      #puts section_xml.xpath("./@end_date")
      #puts "--------> the section xml is #{section_xml}"
      #puts "-------> the course and section ids are: #{section.course_id} #{section.section_id}"
      #binding.pry
      unless section_xml.xpath("./@end_date").empty?
        section.end_date = Time.parse section_xml.xpath("./@end_date").text
      else
        section.end_date = nil
      end
      unless section_xml.xpath("./@start_date").empty?
        section.start_date = Time.parse section_xml.xpath("./@start_date").text
      else
        section.start_date = nil
      end
      if section.kind && section.kind.eql?('joint')
        section.offering_codes = section_xml.xpath("./oars_offerings/oars_offering/@code").collect { |code| code }
      end
      #puts section.start_date
      #puts section.end_dated
      unless section_xml.xpath("./@term_code").empty?
        #at this point the data from this is not used as the crosslist groups are provisioned
        #while processing the matching quarters section.
        section.term_code = section_xml.xpath("./@term_code").text
      end

      @sections[section.section_id] = section


    end

    #puts @sections
    #puts "the total canvas section count is #{@sections.count}"
    @sections
  end

  def Section.sections_canvas_csv(sections)
    #puts users
    CSV.generate do |csv|
      csv << ["section_id", "course_id", "name", "status", "start_date", "end_date"]
      sections.each do |key, section|
        csv << section.to_array(:canvas)
      end
    end
  end

  def to_array(kind)
    #puts "adding section to csv #{self}"
    case kind
      when :canvas
        [section_id, course_id, name, "active", start_date, end_date]
      when :moodle
        [section_id, course_id, name, "active", start_date, end_date]
    end
  end

end
