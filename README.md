# Autodeps

It's like an auto reactive data source, (like in meteor),
when you update one place's data, its change automatically propagate to some other place.
so the basic usage is two places
1.ReactiveData, where the value of dependent changes propagate to the depended on.
2.ReactivePersistency,it's the same idea, but in persisent layer,
normally many times you'll have denormalize data like you copy user's name to
User's message/comment/likes/lauds etc table to improve performance, but the unfortunate
effect is you need to remember to update all those places when your user name changes,
so basiclly it's a custom save inside many after_save hook, very manually and error prone.
the ReactivePersistency solves this problem.

## Installation

Add this line to your application's Gemfile:

    gem 'autodeps'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install autodeps

## Usage

TODO: Write usage instructions here
two parts
1.ReactivePersistency
2.ReactiveData

ReactivePersistency is used in data storage layer, like you have an activerecord/mongomapper persistency layer,
when some properties you want to copy to other table(denormalization), and want to be automatically synced when
main table's property changes,
then just include Autodeps::Persistency and call depend_on  method:
like you have User table, and Laud table, where you copy user.name to Laud.user_name and Laud.dest_user_name
```
class Laud

  include MongoMapper::Document
  include Autodeps::Persistency #adds dependency to Autodeps::Persistency

  key :user_id, Integer, :required => true
  key :user_name, String
  depend_on "User", :value_mapping => {:name => :user_name} #we can omit :key_mapping=> {:id=>:user_id}

  key :dest_user_id, Integer, :required => true
  key :dest_user_name, String
  depend_on "User", :key_mapping => {:id => :dest_user_id}, :value_mapping => {:name => :dest_user_name}

  timestamps!

  ensure_index([[:user_id,1],[:dest_user_id,1]])
end
```
then when you change user's name
```
user.name = "some value"
user.save
```
the name change will automatically propagated to Laud table/collection.

because in development environment, when User loads, the Laud class may not been loaded, so you may want to
do this:
#user.rb
class User
  #some attributes
end
Laud #just adds a reference here to cause rails to load Laud

2.ReactiveData
what ReactiveData means, if you want to say a=b+c
if b or c is ReactiveData, then when b or c's value changes,
a's value automatically changes,it's the concept copyed from meteor:)

see autodeps_test.rb
where a,b is ReactiveData

  def test_reactive_integer
    a = Autodeps::ReactiveData.new(3)
    b = nil
    computation = Autodeps.autorun do |computation| #the block will be rerun if a changes
      b = a.value
    end
    assert_equal b,3

    a.change_to 5

    assert_equal b,5
  end

  def test_reactive_integer_add
    a = Autodeps::ReactiveData.new(3)
    b = Autodeps::ReactiveData.new(5)
    c = nil
    computation = Autodeps.autorun do |computation| #the block will be rerun if a or b changes
      c = a.value + b.value
    end
    assert_equal c,8

    a.change_to 5

    assert_equal c,10

    b.change_to 15

    assert_equal c,20
  end




## Contributing

1. Fork it ( http://github.com/<my-github-username>/autodeps/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
