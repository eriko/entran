class Section
  attr_accessor :section_id, :course_id, :name, :status, :start_date, :end_date, :source_section_id

  def to_s
    "#{section_id} #{course_id} #{name} #{status} #{start_date} #{end_date}"
  end

  def Section.import_xml(lms_courses_xml)
    #The courses to be used are from presence where the course site has been marked requested.
    #Then data from other data sources like the ims.xml feed will be used to gather the full set of data
    #based on the list from presence
    @sections = Hash.new
    lms_courses_xml.xpath("//section").each do |section_xml|

      section = Section.new
      section.section_id = section_xml.xpath("./@section_id").text
      section.course_id = section_xml.xpath("./@course_id").text
      section.name = section_xml.xpath("./@name").text
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
      unless section_xml.xpath("./@source_section_id").empty?
        #at this point the data from this is not used as the crosslist groups are provisioned
        #while processing the matching quarters section.
        section.source_section_id = section_xml.xpath("./@source_section_id").text
      end

      #puts section

      @sections[section.section_id] = section


    end

  #puts @sections
  #puts "the total canvas section count is #{@sections.count}"
  @sections
  end

  def Section.sections_canvas_csv(sections)
    #puts users
    CSV.generate do |csv|
      csv << ["section_id","course_id","name","status","start_date","end_date"]
      sections.each do |key,section|
        csv << section.to_array(:canvas)
      end
    end
  end

  def to_array(kind)
    #puts "adding section to csv #{self}"
    case kind
      when :canvas
        [section_id, course_id,name, "active",start_date,end_date]
      when :moodle
        [section_id, course_id,name, "active",start_date,end_date]
    end
  end

end
