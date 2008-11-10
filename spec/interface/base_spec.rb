require 'spec/spec_helper.rb'

describe Rhino::Interface::Base do
  describe "when working with tables" do
    before do
      # TODO: this is a hardcoded list of tables in my db - should get real fixtures!!
      @table_names = %w(users pages)
      @base = Rhino::Model.connection
    end
    
    it "should return a list of tables" do
      pending "this breaks if you have other tables"
      @base.table_names.should == @table_names
    end
  end
end
