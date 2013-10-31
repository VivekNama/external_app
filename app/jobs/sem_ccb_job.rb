require 'rufus-scheduler'
require 'typhoeus'
require 'json'
require 'rails'

class SemCcbJob
  CRM_NAME = "cc_b"
  SERVER_NAME = "testservicehub.involver.com" #amp2.involver.dev #testservicehub.involver.com
  puts "----Checking for Service Requests for #{CRM_NAME} on #{SERVER_NAME}---"

  def perform
    puts ""
    response = Typhoeus::Request.get("https://testservicehub.involver.com/api/crm_sync", :params => {:crm_name => CRM_NAME})
    #response = Typhoeus::Request.get("https://amp2.involver.dev/api/crm_sync", :params => {:crm_name => CRM_NAME})
    puts response.body

    if response.success?
      puts "response.success"
      sr_infos = JSON.parse(response.body)
      puts "sr_infos.count=#{sr_infos.count}"
      puts "sr_infos=#{sr_infos}"

      if sr_infos.present?

        sr_infos.each do |sr_info|
          puts "sr_info=#{sr_info}"
          puts "post_id=#{sr_info["post_id"]}"

          sr_body =
            {
              "native_id" => sr_info["native_id"],
              "author_name" => sr_info["author_name"],
              "author_id" => sr_info["author_id"],
              "post_id" => sr_info["post_id"],
              "post_link" => sr_info["post_link"],
              "community" => sr_info["community"],
              "topic" => sr_info["topic"],
              "author_first_name" => sr_info["author_first_name"],
              "author_last_name" => sr_info["author_last_name"]
            }
          puts "sr_body=#{sr_body}"

          begin
            incident_num = create_sr sr_body #String(Time.now.hash)
            puts "New incident_num=#{incident_num}"

            puts "URL=http://amp2.involver.dev/api/crm_sync/#{sr_info["post_id"]}"
            response2 = Typhoeus::Request.put("https://testservicehub.involver.com/api/crm_sync/#{sr_info["post_id"]}",
                                              :params => {:crm_name => CRM_NAME, :incident_number => incident_num})
            puts "response2=#{response2}"
            puts "response2.body=#{response2.body}"
            if response2.success?
              puts "response2.success"
              updated_sr_infos = JSON.parse(response2.body)
              puts "updated_sr_infos.count=#{updated_sr_infos.count}"
            end
          rescue Exception => exc
            puts "failure: #{exc.message}"
          end
        end
      end
    end

    #self.class.unlock!
    #self.class.seed
  end

  def create_sr sr_body
    app = Crmodilizer::ServiceRequestService.new(sr_header)
    sr_no = app.create_service_request(sr_body)
  end

  def sr_header
    {
      "username" => 'SOCIALDEV/SEM',  #"weblogic"
      "password" => 'Demo1234',       #"weblogic123"
      "endpoint_url" => 'https://secure-slsomxuha.crmondemand.com/Services/Integration', #"http://soa.srm-ugbu.dyndns.org:7211/soa-infra/services/SRM-CCB/SRMCCBEchoServiceEBF/srmccbservicerequestbpel_client_ep_ep?WSDL"
      "client_name" => 'Oracle SEM'
    }
  end

end

scheduler = Rufus::Scheduler.new

scheduler.every '11s' do
  puts 'Hi ... Rufus'
  SemCcbJob.new.perform
  puts 'By .. Rufus'
end

scheduler.join