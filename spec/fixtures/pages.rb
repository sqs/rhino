page_key = 'example.com'
page_data = {'contents:'=>"<h1>Welcome to Example Page</h1>",
            'title:'=>'Example Page', 'meta:author'=>'John Smith', 'links:com.example.www/path'=>'Click here'}
unless page = Page.find(page_key) and page.data == page_data
  puts "Creating mock Page with key='#{page_key}' and data #{page_data.inspect}"
  Page.create(page_key, page_data)
end