require File.dirname(__FILE__) + '/spec_helper.rb'

describe Rhino::AttrNames do
  describe "when routing attribute calls" do
    it "should route gets for column families" do
      Page.route_attribute_call(:title).should == [:get, 'title:']
    end
    
    it "should route gets for columns" do
      Page.route_attribute_call(:meta_author).should == [:get, 'meta:author']
    end

    it "should route sets for column families" do
      Page.route_attribute_call(:title=).should == [:set, 'title:']
    end
    
    it "should route sets for columns" do
      Page.route_attribute_call(:meta_author=).should == [:set, 'meta:author']
    end
    
    it "should handle unqualified strings (not just symbols)" do
      Page.route_attribute_call('title').should == [:get, 'title:']
    end
    
    it "should handle qualified column family strings" do
      Page.route_attribute_call('title:').should == [:get, 'title:']
    end
    
    it "should handle qualified column strings" do
      Page.route_attribute_call('meta:author').should == [:get, 'meta:author']
    end
    
    it "should reject nil method calls" do
      Page.determine_attribute_name(nil).should == nil
    end
    
    it "should reject empty string method calls" do
      Page.determine_attribute_name('').should == nil
    end
    
    it "should reject nonexistent column families" do
      Page.determine_attribute_name(:doesntexist).should == nil
    end
    
    it "should reject qualified but nonexistent column families" do
      Page.determine_attribute_name('doesntexist:').should == nil
    end
    
    it "should reject qualified but nonexistent columns" do
      Page.determine_attribute_name('doesnt:exist').should == nil
    end
    
    it "should reject nonexistent columns" do
      Page.determine_attribute_name(:doesnt_exist).should == nil
    end
  end
  
  describe "when testing the validity of attribute names" do
    it "should reject columns that aren't in a defined column family" do
      Page.is_valid_attr_name?("addresses:home").should == false
    end

    it "should reject blank attribute names" do
      Page.is_valid_attr_name?("").should == false
      Page.is_valid_attr_name?(nil).should == false
    end

    it "should approve column families" do
      Page.is_valid_attr_name?("meta:").should == true
      Page.is_valid_attr_name?("title:").should == true
    end

    it "should approve columns underneath existing column families" do
      Page.is_valid_attr_name?("meta:author").should == true
      Page.is_valid_attr_name?("title:asdf").should == true
    end
  
    it "should not approve non-fully-qualified column family names" do
      Page.is_valid_attr_name?("meta").should == false
    end
  end

  describe "when converting method names to attribute names" do
    it "should not permit trailing underscores at the end of a method name" do
      lambda { @page.title_ }.should raise_error(NoMethodError)
    end
  
    it "should convert column family names into qualified column family names" do
      Page.underscore_name_to_attr_name('blue').should == 'blue:'
    end
  
    it "should convert underscored column names into qualified column names" do
      Page.underscore_name_to_attr_name('blue_red').should == 'blue:red'
    end
  
    it "should convert symbols as well as strings" do
      Page.underscore_name_to_attr_name(:blue).should == 'blue:'
    end
  end
end