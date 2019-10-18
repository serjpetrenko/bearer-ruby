# Bearer

This gem is a Ruby client to universally call any API using [Bearer.sh](https://www.bearer.sh).

_NB: If you are using Rails, also have a look at the [Rails](https://github.com/bearer/bearer-rails) gem_

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bearer'
```

And then execute:

```shell
$ bundle
```
Or install it yourself as:

```shell
$ gem install bearer
```

## Usage

Grab your Bearer [Secret Key](https://app.bearer.sh/keys) and integration id from
the [Dashboard](https://app.bearer.sh) and then you can use the client as follows:

### Calling any APIs

```ruby
require "bearer"

bearer = Bearer.new("BEARER_SECRET_KEY") # find it on https://app.bearer.sh/keys
github = (
  bearer
    .integration("your integration id") # you'll find it on the Bearer dashboard https://app.bearer.sh
    .auth("your auth id") # Create an auth id for your integration via the dashboard
)

puts github.get("/repositories").data
```

We use `Net::HTTP` internally and we
return it's response from the request methods (`request`,
`get`, `head`, `post`, `put`, `patch`, `delete`).

More advanced examples:

```ruby
# With query parameters
puts github.get("/repositories", query: { since: 364 }).data

# With body data
puts github.post("/user/repos", body: { name: "Just setting up my Bearer.sh" }).data
```

### Global configuration

You can configure the client globally with your [Secret Key](https://app.bearer.sh/keys):

```ruby
Bearer::Configuration.setup do |config|
  config.secret_key = "BEARER_SECRET_KEY" # copy and paste your Bearer `Secret Key`
end
```

You can now use the client without having to pass the Secret Key each time:

```ruby
github = Bearer.integration("your integration id").auth("your auth id")

puts github.get("/repositories").data
```
### Setting the request timeout

By default in bearer client read and open timeouts are set to 5 seconds. Bearer allows to increase the read timeout to up to 30 seconds

```ruby
Bearer::Configuration.setup do |config|
  # increase the request timeout to 10 seconds, and reduce the open connection timeout to 1 second
  config.http_client_settings = { read_timeout: 10, open_timeout: 1 }
end

# it is also possible to set the read_timeout and other Net::HTTP client settings per integration

github = Bearer.integration("your integration id", { read_timeout: 10 })

puts github.get("/repositories").data # This request will timeout after 10 seconds
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment. Also make sure you have `overcommit` installed and initialized in the repo [check overcommit repo](https://github.com/sds/overcommit) for further reference.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bearer/bearer-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Code of Conduct

Everyone interacting in the Bearer project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/bearer/bearer-ruby/blob/master/CODE_OF_CONDUCT.md).
