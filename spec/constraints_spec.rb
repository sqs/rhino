require File.dirname(__FILE__) + '/spec_helper.rb'

describe "when using constraints" do
  before do
    blank_title = ""
    @page = Page.new('some-page', {:title=>blank_title, :contents=>"hello"})
  end
  
  it "should not save objects that violate constraints" do
    lambda { @page.save }.should raise_error(Rhino::ConstraintViolation)
  end
  
  it "should save objects that pass constraints" do
    @page.title = "any title will do"
    lambda { @page.save }.should_not raise_error(Rhino::ConstraintViolation)
  end
end