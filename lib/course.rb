class Course
  require 'pry'
  require 'securerandom'
  attr_accessor :course_id, :curricular_year, :short_name, :long_name, :account_id,
                :status, :start_date, :end_date, :offering_type, :terms, :summary,
                :offering_id, :offering_code, :account_id, :sections, :real_term ,
                :enrollment_term,:offering_codes,:enrollments


  def to_array(kind)
    #puts "#{course_id} #{long_name} #{real_term}"
    case kind
      when :canvas
        puts "the course id being processed is #{course_id}"
        [course_id, short_name, long_name, account_id, real_term.term_id, status, start_date, end_date]
      when :moodle
        [long_name, short_name, 'topic', first_term.start_date.strftime('%d/%m/%G'), self.weeks, self.type_display, course_id, summary, 0, 'manual', 1, 'self', 0, 'Self enrollment (Student)', course_password, "Welcome to #{self.long_name}", 5]
    end
  end

  def course_password
    "#{self.short_name[0..25]}-#{SecureRandom.hex(2)}-TESC"
  end

  def type_display
    case self.offering_type
      when "Program"
        "Academic Offerings/#{Term.acad_year_display(first_term)}/#{first_term.season} #{first_term.calendar_year} Programs"
      when "Course"
        "Academic Offerings/#{Term.acad_year_display(first_term)}/#{first_term.season} #{first_term.calendar_year} Courses"
      when "Cohort"
        "Academic Offerings/Cohorts starting #{Term.acad_year_display(first_term)}/#{first_term.season} #{first_term.calendar_year} Offerings"
    end
  end



  def first_term
    self.terms.sort[0]
  end

  def weeks
    count = 0
    self.terms.each { |term| count += term.weeks.count }
    count

  end

  def Course.import_xml(lms_courses_xml, terms, ims_xml, catalogs, kind, sections,users)
    #The courses to be used are from presence where the course site has beeen marked requested.
    #Then data from other data sources like the ims.xml feed will be used to gather the full set of data
    #based on the list from presence
    @courses = Hash.new
    lms_courses_xml.xpath("//offering").each do |offering|
      #each offering may have any number of websites with will be processed separately
      offering.xpath("./websites/website").each do |website|
        if website.xpath("./type[text()]").text.eql? kind
          #puts "there was a course of #{kind}"
          #course_id will be used as the identifier and for querying the other data sources.
          course_id = website.xpath("./course_id/@id").text
          @course = Object::const_get(website.xpath("./type[text()]").text).new()
          #puts "@course is of type #{@course.class}"
          @course.course_id = course_id
          #binding.pry
          @course.offering_id =  offering.xpath("@offering_id").text
          @course.enrollment_term = offering.xpath("./enrollment_term/@term_code").text
          @course.offering_codes = []
          # start a REPL session
          #binding.pry
          @course.offering_codes = offering.xpath("./oars_offerings/oars_offering/@code").collect { |code| code }
          #puts"offering.oarsofferingcodes--->#{offering.xpath("./oars_offerings")} "
          #puts "the course id is #{course_xml.xpath("./sourcedid/id[text()]").text}"
          @course.short_name = website.xpath("./short_name").text
          @course.long_name = website.xpath("./long_name").text
          @course.account_id = website.xpath("./account_id/@id").text
          @course.terms = website.xpath("./terms/term/@term_code").collect { |term_code| terms[term_code.to_s.to_i] }
          @course.sections = []
          @course.sections = website.xpath("./sections/section/@section_id").collect { |section_id| sections[section_id.to_s] }
          @course.enrollments = []
          #@course.faculty = website.xpath("./people/person/@username").collect {|username| users.values.find{|user| user.login_id.eql?(username.to_s)}}
          #sections = website.xpath("./sections/section/@section_id").collect { |section_id| sections[section_id.to_s] }
          #sections.each do |section_id|
          #  puts "looking for section)id: #{section_id}"
          #  @course.sections << sections[section_id]
          #end
          #puts "the course shortname  is #{@course.short_name}"
          @course.curricular_year = offering.xpath("./curricular_year[text()]").text.to_i

          prime_year= website.xpath("./real_term/@term_code").to_s.to_i
          @course.real_term = terms[prime_year]
          #puts "the real_term is #{ @course.real_term}"

          #this block was used to get catalog data for the description to be used by moodle
          #since we are not using this for moodle I have commented it out.
          #offering_id = offering.xpath("./offeringid").text
          #puts "the offering id is #{offering_id} is #{offering_id.class}"
          #Get the catalog description for the offering
          #@course.summary = catalogs[@course.curricular_year].xpath("/programs/program[@id=#{offering_id}]/description[text()]").text
          #if @course.summary.nil? || @course.summary.length < 1
          #  @course.summary = "Summary unavailable at moodle course creation time"
          #end
          #puts "the @course.summary is #{@course.summary}"
          @course.status = 'active'
          @course.offering_type = offering.xpath("./type[text()]").text
          #@course.start_date = @course.terms.sort[0].start_date.utc.iso8601
          #@course.end_date =@course.terms.sort.last.end_date.utc.iso8601
          @course.start_date = nil
          @course.end_date = nil
          #puts @course.start_date

          #puts @course.course_id
          @courses[@course.course_id] = @course
          #puts "The course in the hash is #{@courses[@course.class][@course.course_id].course_id} and of type #{@course.class}"
        end
      end
    end
    #puts @courses
    #puts "the total moodle course count is #{@courses[MoodleCourse.new.class].count}"
    @courses
  end

end

class CanvasCourse < Course
  def CanvasCourse.courses_csv(courses, global_options)
    CSV.generate do |csv|
      csv << ["course_id", "short_name", "long_name", "account_id", "term_id", "status", "start_date", "end_date"]
      courses.each do |course_id, course|
        #TODO filter out courses that have aready been created
        #unless course_created?(course_id, global_options)
          csv << course.to_array(:canvas)
        #end
      end
    end
  end
end


