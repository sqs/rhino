require 'spec/spec_helper.rb'

describe Rhino::Interface::HBase do
  describe "when working with tables" do
    before do
      # TODO: this is a hardcoded list of tables in my db - should get real fixtures!!
      @table_names = %w(users pages)
      # TODO: there should be a Rhino-namespace way of getting the hbase object, not just through the model
      @hbase = Rhino::Table.hbase
    end
    
    it "should return a list of tables" do
      @hbase.table_names.should == @table_names
    end
  end
end