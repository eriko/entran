class Enrollment
  attr_accessor :user, :role_id, :course_id, :section_id

  @@roles = {student: "Student", faculty: "Teacher"}

  def initialize(user, role_id, course_id, section_id)
    @user = user
    @role_id = role_id
    @course_id = course_id
    @section_id = section_id
  end

  def to_s
    "user #{user} role #{@role_id} course #{@course_id}"
  end

  def to_array(kind)
    case kind
      when :canvas
        [@course_id, @user.user_id, @@roles[role_id], section_id, 'active', nil]
      when :moodle
        [@course_id, @user.user_id, @@roles[role_id], nil, 'active', nil]
    end
  end

  def Enrollment.enrollments_canvas_csv(enrollements)
    CSV.generate do |csv|
      csv << ["course_id", "user_id", "role", "section_id", "status", "associated_user_id"]
      enrollements.each do |enrol|
        csv << enrol.to_array(:canvas)
      end
    end
  end

  def Enrollment.enrollments_moodle_csv(enrollements)
    CSV.generate do |csv|
      csv << ["course_id", "user_id", "role", "section_id", "status", "associated_user_id"]
      enrollements.each do |enrol|
        csv << enrol.to_array(:moodle)
      end
    end
  end

  def Enrollment.import_xml(course, enrollments, users,ims_key)
    offering_id = course.offering_id
    enrollment_term = course.enrollment_term
    puts "course offeringcodes are------->#{course.offering_codes}"

    faculty_section = course.sections.detect { |sec| sec.section_id.eql?("#{offering_id}-faculty") }
    student_section = course.sections.detect { |sec| sec.section_id.eql?("#{offering_id}-#{enrollment_term}") }
    crosslist_section = course.sections.detect { |sec| sec.section_id.eql?("#{offering_id}-#{enrollment_term}-cl") }
    #binding.pry
    course.offering_codes.each do |code|
      url = "http://adminwebtest.evergreen.edu/banner/public/oars/offering/export/offering.xml?offering_code=#{code}&term_code=#{enrollment_term}&key=#{ims_key}"
      puts url
      enrollment_xml = Nokogiri::XML(open(url, :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE))
      #puts "enrollment_xml for #{course.long_name} is -------->#{enrollment_xml}"
      # start a REPL session
      #binding.pry
      enrollment_xml.xpath("./offering/faculty/person").each do |person|
        user,users = User.import_user_xml(person, users)
        enrol = Enrollment.new(user, :faculty, course.course_id, faculty_section.section_id)
        enrollments << enrol
        course.enrollments << enrol
      end
      enrollment_xml.xpath("./offering/registered/person").each do |person|
        user,users = User.import_user_xml(person, users)
        if student_section
        enrol = Enrollment.new(user, :student, course.course_id, student_section.section_id)
        enrollments << enrol
        course.enrollments << enrol
        end
        if crosslist_section
          enrol = Enrollment.new(user, :student, course.course_id, crosslist_section.section_id)
          enrollments << enrol
          course.enrollments << enrol
        end
      end
      #TODO only do this when waitlist is active
      enrollment_xml.xpath("./offering/waitlisted/person").each do |person|
        user,users = User.import_user_xml(person, users)
        if student_section
        enrol = Enrollment.new(user, :student, course.course_id, student_section.section_id)
        enrollments << enrol
        course.enrollments << enrol
        end
        if crosslist_section
          enrol = Enrollment.new(user, :student, course.course_id, crosslist_section.section_id)
          enrollments << enrol
          course.enrollments << enrol
        end
      end
      #TODO only do this when waitlist is active
      enrollment_xml.xpath("./offering/overrides/person").each do |person|
        user,users = User.import_user_xml(person, users)
        if student_section
        enrol = Enrollment.new(user, :student, course.course_id, student_section.section_id)
        enrollments << enrol
        course.enrollments << enrol
        end
        if crosslist_section
          enrol = Enrollment.new(user, :student, course.course_id, crosslist_section.section_id)
          enrollments << enrol
          course.enrollments << enrol
        end
      end
    end

    enrollments
  end

end