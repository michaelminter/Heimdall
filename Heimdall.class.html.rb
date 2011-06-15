<h2>Exact Target API Test Suite</h2>

<%# client = Savon::Client.new "https://webservice.s4.exacttarget.com/etframework.wsdl" %>
<%# client.wsdl.soap_actions.each do |action| %>
	<%# action %><br />
<%# end %>

<%# client.wsse.credentials "loginEmail", "passwordHere" %><%# doesnt return a value %>

<%# response = client.request "retrieve", "EmailAddress" => ("EmailAddress" == "emailToRetrieve") %>
<%# response.inspect %>

<h2>Vertical Response API Testing</h2>

<%
$username = "loginEmail"
$pass = "loginPassword"
$ses_time = 4

require 'rubygems'
require 'soap/wsdlDriver'
require "date"

wsdl = 'https://api.verticalresponse.com/partner-wsdl/1.0/VRAPI.wsdl'  
vr = SOAP::WSDLDriverFactory.new(wsdl).create_rpc_driver

# If you are using the Partner API, uncomment these lines and replace "Certificate_Path" with the path to your .pem certificate
#vr.options['protocol.http.ssl_config.client_cert'] = "Certificate_Path"
#vr.options['protocol.http.ssl_config.client_key'] = "Certificate_Path"
#vr.options['client.protocol.http.ssl_config.verify_mode'] = OpenSSL::SSL::VERIFY_NONE

file_html = '/Users/developer2/git/producttest/public/emails/message_content.html'
html = File.new(file_html, "r")
file_text = '/Users/developer2/git/producttest/public/emails/message_content.txt'
text = File.new(file_text, "r")
subject = "Testing: " + $username +  DateTime.now.to_s

begin
	puts "Login into: " + $username + " ...\n"
	sid = vr.login({
		'username' => $username,
		'password' => $pass,
		'session_duration_minutes' => $ses_time,
		# IF You are using the Partner API, uncomment this line and replace it with the subaccount you wish to impersonate.
		#'impersonate_user' => 'subaccount@example.com'
	})

	#creates a new list and provides a List ID (lid)
	puts "Creating list...\n"
	lid = vr.createList({
		'session_id' => sid,
		'name' => "Mailing List: " + DateTime.now.to_s,
		'type' => 'email'
	})
	puts "Setting up Member Data for list...\n"
	member_data = [
		{
			'name' => 'email_address',
			'value' => 'api-support@verticalresponse.com',               
		},
		{
			'name' => 'First_Name',
			'value' => 'Allen',                
		},
		{
			'name' => 'Last_Name',
 			'value' => 'Corona',
		}
	]

	puts "Adding member record to the list...\n"
	member_record  = vr.addListMember({
		'session_id' => sid,
		'list_member' =>{
			'list_id' => lid,
			'member_data' => member_data,                                
		}
	})

	#lets go ahead and create a campaign
	email_campaign = {
		'name' => "Camp." +  DateTime.now.to_s,
		'type' => "freeform",
		'from_label' => "Test Campaign (123)",
		'support_email' => $username,
		'send_friend' => true,
		'redirect_url' => "http://www.verticalresponse.com",
		'contents' => [
			{
				'type' => 'freeform_html', 
				'copy' => html.read
			},
			{
				'type' => 'freeform_text',
				'copy' => text.read
			},
			{
				'type' => 'subject',
				'copy' => subject
			},{
				'type' => 'unsub_message',
				'copy' => "You requested these emails, now you want to leave? If so ",
			}                                              
		],    
	}

	#sending request to the VR
	puts "Creating message...\n"
	cid = vr.createEmailCampaign({
		'session_id' => sid,
		'email_campaign' => email_campaign,                  
	})
	#sending Test message
	test_list = [
		[{
			'name' => 'email_address',
			'value' => 'michael.minter@twgplus.com'
		},{
			'name' => 'First_Name',
			'value' => 'VR_User'
		}
		],[{
			'name' => 'email_address',
			'value' => 'api-support@verticalresponse.com'
		},{
			'name' => 'First_Name',
			'value' => 'michael.minter@twgplus.com'
		}]
	]
	puts "Sending test message...\n"
	temp0 = vr.sendEmailCampaignTest({
		'session_id' => sid,
		'campaign_id' => cid,
		'recipients' => test_list,
	})

	puts "Deploying message...You should receive it shortly...\n"
	# attaching the list to the message
	temp = vr.setCampaignLists({
		'session_id' => sid,
		'campaign_id' => cid,
		'list_ids' => [lid],
	})

	puts "end of sample code\n"
rescue Exception => e
	puts "There was an error: " + e
end
%>