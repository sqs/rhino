#################################
# Rails app integration example #
#################################
# WARNING: right now, this is just pasted from an app -- 
# it's meant to be read by you and perhaps pasted into your app, not executed directly

# schema: users(email:, pages:)
# in the ruby shell: create 'users', 'info', 'pages'



####################################
# app/models/page.rb
####################################
class Page < Rhino::Cell
  belongs_to :user
  
  def name=(a_name)
    self.key=a_name
  end
  
  def name
    key
  end
  
  ### the following methods are hacks to give Rails false info when using
  ### form_for and other helpers
  ### these will eventually be in Rhino::ActiveRecordImpersonation
  def id
    0
  end
  
  def errors
    []
  end
  
  def updated_at
    Time.now - rand(150000)
  end
end

####################################
# app/models/user.rb
####################################
class User < Rhino::Base
  column_family :info
  column_family :pages
  
  has_many :pages, Page
  
  alias_attribute :email, 'info:email'
  alias_attribute :password, 'info:password'
  
  def login
    key
  end
end

####################################
# config/environment.rb
####################################
...
Rails::Initializer.run do |config|
  config.frameworks -= [ :active_record, :active_resource, :action_mailer ]
  ...
end

require '/Users/sqs/proj/rhino/lib/rhino'

Rhino::Cell.send(:extend, Rhino::ActiveRecordImpersonation::CellClassMethods)
Rhino::Cell.send(:include, Rhino::ActiveRecordImpersonation::CellInstanceMethods)
Rhino::Base.connect('localhost', '9090')

####################################
# app/controllers/pages_controller.rb
####################################
class PagesController < ApplicationController
  before_filter :find_user

  def index
    @pages = @user.pages

    respond_to do |format|
      format.html
      format.xml { render(:xml=>@pages.to_xml) }
    end
  end

  def show
    find_page
    
    respond_to do |format|
      format.html
      format.xml  { render :xml => @page }
    end
  end

  def new
    @page = @user.pages.add('', '')

    respond_to do |format|
      format.html
      format.xml  { render :xml => @page }
    end
  end

  def edit
    find_page
  end

  def create
    @page = @user.pages.add(params[:page][:name], params[:page][:contents])
    respond_to do |format|
      if @page.save
        flash[:notice] = 'File created.'
        format.html { redirect_to(page_url(@page)) }
        format.xml  { render :xml => @page, :status => :created, :location => @page }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @page.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    find_page
    @page.name = params[:page][:name]
    @page.contents = params[:page][:contents]

    respond_to do |format|
      if @page.save
        flash[:notice] = 'File saved.'
        format.html { redirect_to(page_url(@page)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @page.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    find_page
    @page.destroy

    respond_to do |format|
      format.html { redirect_to(pages_url(@current_user)) }
      format.xml  { head :ok }
    end
  end
end