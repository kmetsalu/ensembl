# Ensembl

Gem to access ensembl.org database. Currently only supports Variation database tables and latest version.

Some of the work is inspired of [ruby-ensembl-api] project.

## Installation

Add this line to your application's Gemfile:

    gem 'ensembl'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ensembl

## Usage

    require 'ensembl'

### ENSEMBL.ORG database - Default configuration
    
    Ensembl::Variation::Variation.first
    
    Ensembl::Variation::Variation.first.source

### Custom database
    
    # Set following values before using - Only Human databases is somewhat tested.
    
    Ensembl.host = 'myhost.example.com'
    Ensembl.port = 3306                                 # default
    Ensembl.username = 'anonymous'                      # default
    Ensembl.password = ''                               # default
    Ensembl.species = 'homo_sapiens'                    # default
    Ensembl.version = 75                                # default
    Ensembl.hg_version = 37                             # default
    

## Contributing

1. Fork it ( https://github.com/kmetsalu/ensembl/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request


[ruby-ensembl-api]: https://github.com/jandot/ruby-ensembl-api
