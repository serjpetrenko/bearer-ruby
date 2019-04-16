# Bearer

This gem is a Ruby client to interact with [Bearer](https://www.bearer.sh)'s integrations.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bearer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bearer

## Usage

Get your Bearer's [credentials](https://app.bearer.sh/keys) and setup Bearer as follow:

```ruby
Bearer::Configuration.setup do |config|
    config.api_key = "secret_api_key" # copy and paste the `API key`
    config.client_id = "client_id" # copy and paste the `Client ID`
end
```

Invoke the Function:

```ruby
Bearer.invoke(
    "4l1c3", # Integration UUID
    "fetch-goats", # Function Name
    params: {
        setupId: "my-setup-id"
    }
)
```

_NB: If you are using Rails, have a look at the [Rails](https://github.com/bearer/bearer-rails) gem_

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bearer/bearer-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Code of Conduct

Everyone interacting in the Bearer project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/bearer/bearer-ruby/blob/master/CODE_OF_CONDUCT.md).
