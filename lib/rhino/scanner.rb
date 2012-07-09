module Rhino
  class Scanner
    include Enumerable
    
    attr_reader :opts, :columns
    def initialize(model, opts)
      @model = model
      @opts = opts
      @columns = if opts.has_key? :columns
        opts[:columns]
      else
        model.column_families
      end
      
      @scanner = Rhino::Model.adapter::Scanner.new(@model.table, @columns, self.opts)
    end
    
    def each
      while row_data = @scanner.next_row()
        row_key = row_data.delete('key')
        row = @model.load(row_key, row_data)
        yield(row)
      end
    end
  end
end