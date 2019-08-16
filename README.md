# ActiveRecord::Relatives

[![Build Status](https://travis-ci.org/samesystem/activerecord-relatives.svg?branch=master)](https://travis-ci.org/samesystem/activerecord-relatives)
[![codecov](https://codecov.io/gh/samesystem/activerecord-relatives/branch/master/graph/badge.svg)](https://codecov.io/gh/samesystem/activerecord-relatives)
[![Documentation](https://readthedocs.org/projects/ansicolortags/badge/?version=latest)](https://samesystem.github.io/activerecord-relatives)

This tool will help you find all the associations and their ids related with given model.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activerecord-relatives'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install activerecord-relatives

## Usage

This tool will find all ids related with given model. Let's say your models look something like this:

```ruby
class User < ActiveRecord::Base
  has_many :comments
  has_many :posts
end

class Post < ActiveRecord::Base
  belongs_to :author, class_name: 'User'
end

class Comment < ActiveRecord::Base
  belongs_to :post
end
```

and your data looks like this:

```ruby
user1 = User.create! #=> #<User id: 1>
post1 = Post.create(author: user1) #=> #<Post id: 1 ...>
post2 = Post.create(author: user1) #=> #<Post id: 2 ...>
Comment.create!(post: post1) #=> #<Comment id: 1 ...>

user2 = User.create! #=> #<User id: 2>
post3 = Post.create(author: user1) #=> #<Post id: 3 ...>
Comment.create!(post: post3) #=> #<Comment id: 3 ...>
```

then `ActiveRecord::Relatives` will return all ids which are somehow related for a given record:

```ruby
ActiveRecord::Relatives.call(user1) # => { Post => [1, 2], Comment => [1] }
```

## Requirements

In order to make this tool work you need to have your associations properly set

## Usage examples

This tool can be handy for various tasks, like:

* removing records with all associations
* detecting data which has missing associations (like, after incomplete delete)
* analyzing dependencies
* detecting circular dependencies
* detecting out of sync objects (like, objects which are related with multiple users, but they shouldn't)
* detecting god models
* generating UML diagrams
* you name it :)

### Removing records with all associations

```ruby
ActiveRecord::Base.transaction do
  ActiveRecord::Relatives.call(user1).each do |model, data|
    model.unscoped.where(id: data.ids).delete_all
  end
end
```

### Detecting out of sync objects

```ruby
records_without_user = []
ActiveRecord::Relatives.call(User.all.unscoped).each do |model, data|
  records_without_user << model.unscoped.where.not(id: data.ids)
end
```

### Analyzing dependencies

```ruby
post_dependency = ActiveRecord::Relatives
  .call(user1)
  .dependencies
  .detect { |dependency| dependency.key?(Post) }
post_dependency.depends_on #=> [User, Image, ...]
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/samesystem/activerecord-relatives. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ActiveRecord::Relatives project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/samesystem/activerecord-relatives/blob/master/CODE_OF_CONDUCT.md).
