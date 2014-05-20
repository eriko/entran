class Account
  attr_accessor :account_id, :name, :id
  parent_account_id = nil
  status = 'active'


  def Account.import_xml(lms_courses_xml, canvas)
    #The courses to be used are from presence where the course site has beeen marked requested.
    #Then data from other data sources like the ims.xml feed will be used to gather the full set of data
    #based on the list from presence
    @accounts = Hash.new
    lms_courses_xml.xpath("//account").each do |section_xml|

      account = Account.new
      account.account_id = section_xml.xpath("./@account_id").text
      account.name = section_xml.xpath("./@name").text

      begin
        c_account = canvas.get("/api/v1/accounts/sis_account_id:#{account.account_id}")
          account.id = c_account['id']
          puts "that account id for #{account.account_id} is #{account.id}"
      rescue => error

      end


      @accounts[account.account_id] = account


    end

    #puts @sections
    #puts "the total canvas section count is #{@sections.count}"
    @accounts
  end

  def Account.accounts_canvas_csv(accounts)
    #puts users
    CSV.generate do |csv|
      csv << ['account_id', 'parent_account_id', 'name', 'status']
      accounts.values do |account|
        csv << account.to_array(:canvas)
      end
    end
  end

  def to_array(kind)
    case kind
      when :canvas
        [account_id, '', name, "active"]
      when :moodle
        [section_id, course_id, name, "active", start_date, end_date]
    end
  end


end