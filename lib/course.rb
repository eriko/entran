class Course
  attr_accessor :course_id, :curricular_year, :short_name, :long_name, :account_id, :status, :start_date, :end_date, :offering_type, :terms, :summary


  def to_array(kind)
    case kind
      when :canvas
        [course_id, short_name, long_name, 1, first_term.term_id, status, start_date, end_date]
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

  def Course.import_xml(lms_courses_xml, terms, ims_xml, catalogs, kind)
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
          course_xml = ims_xml.xpath("//enterprise/group/sourcedid/id[text()='#{course_id}']/../..")
          #make sure that there is data in the ims feed for the website.  Some offerings
          #may be listed in presence that have yet to be represented in the ims feed.
          #this could be because the offering is not a Program and so only gets generated
          #a couple months before the start of the course.
          if course_xml.size > 0 #only create courses that are in the ims feed also
            @course = Object::const_get(website.xpath("./type[text()]").text).new()
            #puts "@course is of type #{@course.class}"
            @course.course_id = course_id
            #puts "the course id is #{course_xml.xpath("./sourcedid/id[text()]").text}"
            @course.short_name = course_xml.xpath("./description/short[text()]").text
            @course.long_name = course_xml.xpath("./description/long[text()]").text
            @course.terms = website.xpath("./terms/term/@term_code").collect { |term_code| terms[term_code.to_s.to_i] }
            #puts "the course shortname  is #{@course.short_name}"
            @course.curricular_year = offering.xpath("./curricular_year[text()]").text.to_i

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
            @course.start_date = @course.terms.sort[0].start_date.utc.iso8601
            @course.end_date =@course.terms.sort.last.end_date.utc.iso8601
            #puts @course.start_date

            #puts @course.course_id
            @courses[@course.course_id] = @course
                                 #puts "The course in the hash is #{@courses[@course.class][@course.course_id].course_id} and of type #{@course.class}"
          end
        end
      end
    end
    #puts @courses
    #puts "the total moodle course count is #{@courses[MoodleCourse.new.class].count}"
    @courses
  end

end

class CanvasCourse < Course

  def CanvasCourse.courses_csv(courses)
    CSV.generate do |csv|
      csv << ["course_id", "short_name", "long_name", "account_id", "term_id", "status", "start_date", "end_date"]
      courses.each do |course_id, course|
        csv << course.to_array(:canvas)
      end
    end
  end
end

class MoodleCourse < Course
  def MoodleCourse.courses_csv(courses)
    CSV.generate do |csv|
      csv << ["fullname", "shortname", "format", 'startdate', 'numsections', "category", "idnumber", "summary", "visible", 'enrolmethod_1', 'status_1', 'enrolmethod_2', 'status_2', 'name_2', 'password_2', 'customtext1_2', 'roleid_2']
      #puts "adding courses to courses.xml file with #{courses}"
      courses.each do |course_id, course|
        puts course_id
        csv << course.to_array(:moodle)
      end
    end
  end
end
#Enrolment methods need special CSV columns as there can be many per course, and the fields for each
#method are flexible.The following is an example with two enrolment methods - manual, and self - firstly you need
#the column identifying the enrolment method enrolmethod_<n>, and then add the corresponding field values subscripted with _<n>.
#    eg :
#fullname,  shortname,  category, idnumber, summary,  enrolmethod_1,  status_1, enrolmethod_2,  name_2, password_2, customtext1_2
#Parent,    Parent,   ,           Parent,   Parent,   manual,         1,        self,           self1,  letmein,    this is a custom message 1
#Students,  Students, ,           Students, Students, manual,         0,        self,           self2,  letmein,    this is a custom message 2
#Teachers,  Teachers, ,           Teachers, Teachers, manual,         0,        self,           self3,  letmein,    this is a custom message 3

#fullname, shortname, category, idnumber, summary,
#    format, showgrades, newsitems, teacher, editingteacher, student, modinfo,
#    manager, coursecreator, guest, user, startdate, numsections, maxbytes, visible, groupmode, restrictmodules,
#    enablecompletion, completionstartonenrol, completionnotify, hiddensections, groupmodeforce, lang, theme,
#    cost, showreports, notifystudents, expirynotify, expirythreshold, requested,