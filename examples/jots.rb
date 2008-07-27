# schema: users(email:, jots:)
# in the ruby shell: create 'users', 'email', 'jots'

require 'lib/rhino'

include Rhino::Debug

Rhino::Base.connect("http://localhost:60010/api")

class Jot < Rhino::Cell
  belongs_to :user
end

class User < Rhino::Base
  column_family :email
  column_family :jots
  
  has_many :jots, Jot
end

sqs = User.find('sqs') || 
    ( User.create('sqs', :email=>'user@example.com') &&
      sqs.set_attribute('jots:Flights', 'SQ27 EWR-SIN') &&
      sqs.set_attribute('jots:Friends', 'Sally, Billy, Bob, John') )

sqs.save


u = User.find('sqs')
puts "User inspect: #{u.inspect}"
puts
puts "Listing jots:"
u.jots.keys.each do |jot_key|
  puts "#{jot_key}: #{u.jots[jot_key].contents}"
end
puts