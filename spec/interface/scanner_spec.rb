require 'spec/spec_helper.rb'

describe Rhino::Interface::Scanner do
  before do
    @page_htable = Page.htable
    @page_htable.put('a', {'title:'=>'abc'})
    @page_htable.put('b', {'title:'=>'bcd'})
    @page_htable.put('c', {'title:'=>'cde'})
  end
  
  after do
    @page_htable.delete_all
  end
  
  describe "using a non-constrained scanner" do
    it "should find all rows" do
      row_titles = %w(abc bcd cde)
      row_keys = %w(a b c)
      rows = []
      rows = @page_htable.scan.collect
      rows.collect { |row| row['title:'] }.should == row_titles
      rows.collect { |row| row['key'] }.should == row_keys
    end
  end
end