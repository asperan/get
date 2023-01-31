# Get
Get is a toolbox based on git. Get simplifies the adoption of semantic version, conventional commits and good licensing, other than some shortcuts to git commands.

## Installation
Get is considered a standalone gem, so it is not designed to be a dependency, but if needed you can add this line to your application's Gemfile:

```ruby
gem 'git_toolbox', '~> 0.4.0'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install git_toolbox

## Usage
`get` is a toolbox for git: you can write `get -h` to view the available subcommands and options. Subcommands have the option `-h` too.

This is the structure of the help text:
```
Usage: get -h|-v|(<subcommand> [<subcommand-options])
Subcommands:
  describe => Describe the current git repository with semantic version
  commit   => Create a new semantic commit
  init     => Initialize a new git repository with an initial empty commit


Get version: 0.3.0
Options:
  -v, --version    Print version and exit
  -h, --help       Show this message

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.

<!-- To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org). -->

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/asperan/get.

## License

Get is released under the [GNU LGPL v3.0](https://www.gnu.org/licenses/lgpl-3.0-standalone.html) license, based on the [GNU GPL v3.0](https://www.gnu.org/licenses/gpl-3.0-standalone.html) license.
