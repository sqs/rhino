require 'spec/spec_helper.rb'

# TODO these tests should not be dependent on Rhino::Model (Page is a subclass of Model)
describe Rhino::Interface::HTable do
  before do
    @page_htable = Page.htable
  end
  
  after do
    @page_htable.delete_all_rows
  end
  
  describe "when getting rows" do
    it "should raise RowNotFound for nonexistent rows" do
      lambda { @page_htable.get('this row key does not exist') }.should raise_error(Rhino::Interface::HTable::RowNotFound)
    end
    
    it "should raise ArgumentError if nil or blank key is given" do
      lambda { @page_htable.get('') }.should raise_error(ArgumentError)
      lambda { @page_htable.get(nil) }.should raise_error(ArgumentError)
    end
    
    it "should get the latest timestamp" do
      ts = (Time.now.to_f * 1000).to_i
      @page_htable.put('abc', {'title:'=>'hello1', 'contents:'=>'hello there'}, ts)
      @page_htable.put('abc', {'title:'=>'hello2'}, ts+1000)
      @page_htable.put('abc', {'title:'=>'hello3'}, ts+5000)
      @page_htable.get('abc')['timestamp'].should == ts+5000
    end
    
    it "should get the timestamp" do
      @page_htable.put('a99', {'title:'=>'hello2'})
      @page_htable.get('a99')['timestamp'].should be_close((Time.now.to_f * 1000).to_i, 100)
    end
    
    it "should retrieve the row" do
      key = 'hello.com'
      @page_htable.put(key, {'title:'=>'howdy'})
      row = @page_htable.get(key)
      row.keys.sort.should == %w(timestamp title:)
      row['title:'].should == 'howdy'
    end
  end
  
  describe "when deleting all rows" do
    before do
      @page_htable.put('a', {'title:'=>'abc'})
      @page_htable.put('b', {'title:'=>'bcd'})
      @page_htable.put('c', {'title:'=>'cde'})
    end
    
    it "should remove all rows" do
      @page_htable.get('a').should_not == nil
      @page_htable.delete_all_rows
      lambda { @page_htable.get('a') }.should raise_error(Rhino::Interface::HTable::RowNotFound)
      @page_htable.scan.collect.should == []
    end
  end
  
  describe "when deleting entire rows" do  
    before do
      @some_key = 'some-key'
      @page_htable.put(@some_key, {'title:'=>'abc'})
    end
    
    it "should delete the row" do
      @page_htable.get(@some_key).should_not == nil
      @page_htable.delete_row(@some_key)
      lambda { @page_htable.get(@some_key) }.should raise_error(Rhino::Interface::HTable::RowNotFound)
    end
  end
  
  describe "when putting rows" do
    it "should require that column values be strings" do
      lambda { @page_htable.put('a', {'title:'=>Object}) }.should raise_error(ArgumentError)
    end
  end
  
  describe "when putting existing rows" do
    it "should delete cells that previously existed if their value is changed to nil" do
      key = 'example.com'
      @page_htable.put(key, {'title:'=>'howdy', 'links:com.google'=>'Google'})
      @page_htable.get(key).keys.include?('links:com.google').should == true
      # the cell has been deleted
      @page_htable.put(key, {'title:'=>'howdy', 'links:com.google'=>nil})
      @page_htable.get(key).keys.include?('links:com.google').should == false
    end
  end
  
  describe "when putting new rows" do
    describe "when the row is new" do
      it "should create the row before mutating its values"
    end
    
    it "should update the values" do
      key = 'hi.example.com'
      @page_htable.put(key, {'title:'=>'howdy'})
      @page_htable.get(key)['title:'].should == 'howdy'
      @page_htable.put(key, {'title:'=>'goodbye'})
      @page_htable.get(key)['title:'].should == 'goodbye'
    end
  end
end