class Settings
  attr_accessor  :canvas_training_id ,:canvas_templates


  def initialize(lms_courses_xml)
    @canvas_training_id = lms_courses_xml.xpath("/offering_feed/canvas_training_course_id/@id").text
    templates = lms_courses_xml.xpath("./offering_feed/canvas_templates/canvas_template").collect { |template| [template[:name],template[:course_id]]  }
    @canvas_templates = templates.to_h
  end


end