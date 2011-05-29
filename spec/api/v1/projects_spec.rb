require "spec_helper"

describe "/api/v1/projects", :type => :api do
  let(:user) {  create_user! }
  let(:token) { user.authentication_token }

  context "projects viewable by this user" do
    let(:project) { Factory(:project) }

    before do
      user.permissions.create!(:action => "view", :thing => project)

      Factory(:project, :name => "Access denied.")
    end

    let(:url) { "/api/v1/projects" }
    it "JSON" do
      get "#{url}.json", :token => token

      projects_json = Project.for(user).all.to_json
      last_response.body.should eql(projects_json)
      last_response.status.should eql(200)

      projects = JSON.parse(last_response.body)

      projects.any? do |p|
        p["project"]["name"] == "Ticketee"
      end.should be_true
      
      projects.any? do |p|
        p["project"]["name"] == "Access Denied"
      end.should be_false
    end
    
    it "XML" do
      get "#{url}.xml", :token => token
      last_response.body.should eql(Project.readable_by(user).to_xml)
      projects = Nokogiri::XML(last_response.body)
      projects.css("project name").text.should eql("Ticketee")
    end
  end
  
  context "creating a project" do
    before do
      user.admin = true
      user.save
    end

    let(:url) { "/api/v1/projects" }

    it "sucessful JSON" do
      post "#{url}.json", :token => token,
                          :project => {
                            :name => "Ticketee"
                          }

      project = Project.find_by_name("Ticketee")
      route = "/api/v1/projects/#{project.id}"

      last_response.status.should eql(201)
      last_response.headers["Location"].should eql(route)
      
      last_response.body.should eql(project.to_json)
    end
    
    it "unsuccessful JSON" do
      post "#{url}.json", :token => token,
                          :project => {}
      last_response.status.should eql(422)
      errors = {"name" => ["can't be blank"]}.to_json
      last_response.body.should eql(errors)
    end
  end
end