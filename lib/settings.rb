class Settings
  attr_accessor :canvas_syllabus, :canvas_homepage, :canvas_training_id ,
                :canvas_module_description,:canvas_module_syllabus ,:canvas_module_week1


  def initialize(lms_courses_xml)
    @canvas_syllabus = Base64.decode64(lms_courses_xml.xpath("/offering_feed/canvas_syllabus").text)
    @canvas_homepage = Base64.decode64(lms_courses_xml.xpath("/offering_feed/canvas_homepage").text)
    @canvas_module_description = Base64.decode64(lms_courses_xml.xpath("/offering_feed/canvas_module_description").text)
    @canvas_module_syllabus = Base64.decode64(lms_courses_xml.xpath("/offering_feed/canvas_module_syllabus").text)
    @canvas_module_week1 = Base64.decode64(lms_courses_xml.xpath("/offering_feed/canvas_module_week1").text)
    @canvas_training_id = lms_courses_xml.xpath("/offering_feed/canvas_training_course_id/@id").text
  end

  def to_s
    "@canvas_syllabus = #{self.canvas_syllabus} "+"@canvas_homepage = #{self.canvas_homepage} "+"@canvas_module_description = #{self.canvas_module_description} "+"@canvas_module_syllabus = #{self.canvas_module_syllabus} "+"@canvas_module_week1 = #{self.canvas_module_week1} "+"@canvas_training_id = #{self.canvas_training_id} "
  end
end