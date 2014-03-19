class Enrollment
  attr_accessor :user, :role_id, :course_id, :section_id

  @@roles = {1 => "Student", 2 => "Teacher"}

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

  def Enrollment.import_xml(course, ims_xml, enrollments, users, offering_id)
    #puts "the course has #{course.sections.count} sections"
    course.sections.each do |section|
      #find out if there is a cross list and if so later we will add an enrollment to it.
      crosslist = course.sections.detect { |sec| sec.section_id.eql?("#{section.section_id}-cl") }
      faculty = course.sections.detect { |sec| sec.section_id.eql?("#{offering_id}-faculty") }
      #puts "looking for people in section #{section}"

      ims_xml.xpath("//membership/sourcedid/id[text()='#{section.section_id}']/../../member").each do |member|
        #puts "the member xml is -------> #{member}"
        user_id = member.xpath("./sourcedid/id[text()]").text
        role_id = member.xpath("./role/@roletype").text.to_i
        @user = users[user_id]
        if @user.nil?
          puts "user was nil"
        end
        #TODO  catch error of user in course enrollment but not in the list of users
        if role_id == 1 #only add students
          enrol = Enrollment.new(@user, role_id, course.course_id, section.section_id)
          enrollments << enrol
          if crosslist #if there is a crosslist use it to add an enrollemnt to it.
            enrol = Enrollment.new(@user, role_id, course.course_id, crosslist.section_id)
            enrollments << enrol
          end
        elsif role_id == 2  && faculty
          enrol = Enrollment.new(@user, role_id, course.course_id,"#{offering_id}-faculty" )
          enrollments << enrol
        end
      end
    end
    enrollments
  end

end