class Account
   attr_accessor :account_id , :name
   parent_account_id = nil
   status = 'active'




   def Account.import_xml(lms_courses_xml)
     #The courses to be used are from presence where the course site has beeen marked requested.
     #Then data from other data sources like the ims.xml feed will be used to gather the full set of data
     #based on the list from presence
     @accounts = []
     lms_courses_xml.xpath("//account").each do |section_xml|

       account = Account.new
       account.account_id = section_xml.xpath("./@account_id").text
       account.name = section_xml.xpath("./@name").text


       @accounts << account


     end

     #puts @sections
     #puts "the total canvas section count is #{@sections.count}"
     @accounts
   end

   def Account.accounts_canvas_csv(accounts)
     #puts users
     CSV.generate do |csv|
       csv << ['account_id','parent_account_id','name','status']
       accounts.each do |account|
         csv << account.to_array(:canvas)
       end
     end
   end

   def to_array(kind)
     case kind
       when :canvas
         [account_id, '',name, "active"]
       when :moodle
         [section_id, course_id,name, "active",start_date,end_date]
     end
   end


end