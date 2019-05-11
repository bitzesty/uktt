# UKTT

Uktt provides a way to work with the UK Trade Tariff API, https://api.trade-tariff.service.gov.uk/#gov-uk-trade-tariff-api.

###  Features
- Fetches sections, chapters, headings, commodities, goods_nomenclatures, monetary exchange rates, and quota definitions from the Tariff API
- Covers both `v1` and `v2` of the API
- Tests local, production, and any other Frontend API servers using real (not mocked) API calls
- Produces printable Tariff PDF files for chapters
- Command-line interface

## Installation

The repository is here: __https://github.com/mcumcu/uktt__

<!-- The [project](https://gitlab.bitzesty.com/christopher.unger/uktt) is on BitZesty gitlab, and access is set to "internal", so that it can be cloned by any logged in BitZesty user. -->

Add to your Gemfile:

```ruby
gem 'uktt'
```

## Usage

### Set options

Set library-wide options using a hash. Here are the current defaults:
```ruby
opts = {
  host: 'http://localhost:3002',  #  use a local frontend server
  version: 'v1',                  #  `v1` and `v2` are supported
  debug: false,                   #  dislays request and response info
  return_json: false              #  returns OpenStruct by default
}
```

Set options upon instantiation, and change them on the instance by passing-in a hash to overwrite existing or create new options:
```ruby
# Instatiate an new object with options:

> s = Uktt::Section.new(opts.merge(section_id: '1'))

# or, set `section_id` with accessor. Only `*_id` options have accessors.

> s = Uktt::Section.new
> s.section_id = '1'

# => #<Uktt::Section @section_id="1", @config={:host=>"http://localhost:3002", :version=>"v1", :debug=>false, :return_json=>false}>

> s.config = {version: 'v2', return_json: true, section_id: '2'}
> s.inspect

# => #<Uktt::Section @section_id="2", @config={:host=>"http://localhost:3002", :version=>"v2", :debug=>false, :return_json=>true}>

# NOTE: `Uktt::Section` has accessors. Other objects also have *_id accessors.

> s.section_id

# => "2"

> s.section_id = '3'

# => #<Uktt::Section @section_id="3", @config={:host=>"http://localhost:3002", :version=>"v2", :debug=>false, :return_json=>true}> 

```

Options may be loaded from a YAML configuration file:

```yaml
# uktt.yaml
---
  host: http://foo.bar:999
  version: v2
  debug: false
  return_json: false
```


Load options from file:

```ruby
> Uktt.configure_with('./uktt.yaml')

# => {"host"=>"http://foo.bar:999", "version"=>"v2", "debug"=>false, "return_json"=>false}
```

### Retrieve one object

Retrieve an object as an OpenStruct, then retrieve it as JSON

```ruby
> s.retrieve

# => #<OpenStruct data=#<OpenStruct id="3", type="section", attributes=#<OpenStruct ... >>>

> s.config = {return_json: true}
> s.retrieve

# => {"data":{"id":"3","type":"section","attributes":{"id": ... }}}

```

### Retrieve collections of objects

Retrieve all sections using `v2`, then switch to `v1`:

```ruby
> s.retrieve_all

# => #<OpenStruct data=[#<OpenStruct id="1", type="section", attributes=#<OpenStruct ... >>]>

> s.config = {version: 'v1'}
> s.retrieve_all

# => [#<OpenStruct id=1, position=1, title="Live animals; animal products", numeral="I", ...>]
```

### Quota search

Retrieve quota definitions, optionally filtered by various criteria. The search criteria are passed-in with a hash:

```ruby
> criteria = {
    goods_nomenclature_item_id: '0805102200',
    year: '2018',
    geographical_area_id: 'EG',
    order_number: '091784',
    status: 'not blocked',
    critical: 'N'
  }
> quotas = Uktt::Quota.new(version: 'v2') # must use `v2`
> quotas.search(criteria)

# => #<OpenStruct data=[#<OpenStruct id="12202", type="definition", attributes=#<OpenStruct quota_definition_sid=12202, quota_order_number_id="091784" ... >>]>
```
### Goods nomenclatures

Retrieves goods nomenclatures by heading, chapter, or section.

E.g., use a heading object to retrieve all associated goods nomenclatures:

```ruby
> h = Uktt::Heading.new(heading_id: '0101')
> h.goods_nomenclatures

# => #<OpenStruct data=[#<OpenStruct id="27624", type="goods_nomenclature", attributes=#<OpenStruct goods_nomenclature_item_id="0101000000", ... >>]>
```

### API Testing

The Uktt gem may be used to test the Trade Tariff API. The specs _do not_ use mocks-- and will make real API requests against a Trade Tariff frontend server, e.g., local, dev, staging, or production.

Run tests using default server (localhost:3002) and default API version `v1`:

```bash
$ rake spec
```

To run tests using API version `v2`, set the `VER` environment variable:

```bash
$ VER=v2 rake spec
```

To run tests against any Trade Tariff Frontend server, set the `HOST` variable, or use a shortcut `PROD=true` to set the host to the production server:

```bash
$ HOST=https://dev.trade-tariff.service.gov.uk rake spec

# or using a shortcut for production:

$ PROD=true rake spec

# envorinment variables may be combined:

$ HOST=https://localhost:3002 VER=v2 rake spec
```

### PDF

The Uktt gem can produce PDF files for individual chapters of the Tariff.

Set `chapter_id` and optional `filepath` with a hash.

```ruby
> p = Uktt::Pdf.new
> p.config = {chapter_id: '01', filepath: './Chapter-01.pdf'}
> p.make_chapter
```

## Command line interface

This gem provides a command-line interface (CLI).

```bash
$ uktt

Commands:
  uktt chapter                  # Retrieves a chapter
  uktt chapters                 # Retrieves all chapters
  uktt commodity                # Retrieves a commodity
  uktt heading                  # Retrieves a heading
  uktt help [COMMAND]           # Describe available commands or one specific command
  uktt info                     # Prints help for `uktt`
  uktt monetary_exchange_rates  # Retrieves monetary exchange rates
  uktt pdf                      # Makes a PDF of a chapter
  uktt section                  # Retrieves a section
  uktt sections                 # Retrieves all sections
  uktt test                     # Runs API specs

Options:
  -h, --host, [--host=http://localhost:3002]            # Use specified API host, otherwise `http://localhost:3002`
  -a, --api-version, [--version=v1]                     # Request a specific API version, otherwise `v1`
  -d, --debug, [--debug=true], [--no-debug]             # Show request and response headers, otherwise not shown
  -j, --json, [--return-json=true], [--no-return-json]  # Request JSON response, otherwise OpenStruct
  -p, --production, [--prod=true]                       # Use production API host, otherwise `http://localhost:3002`
  -g, --goods, [--goods=GOODS]                          # Retrieve goods nomenclatures in this object
  -n, --note, [--note=NOTE]                             # Retrieve a note for this object
  -c, --changes, [--changes=CHANGES]                    # Retrieve changes for this object
```

Here are some examples of the CLI:

```bash
# basic usage
$ uktt sections                 # get all sections
$ uktt section 1                # get one section
$ uktt section 1 -j             # get JSON
$ uktt section 1 -jp            # get JSON, from prod.
$ uktt section 1 -jp -a v2      # get JSON, from prod., use `v2`
$ uktt monetary_exchange_rates  # get a collection

# get an object
$ uktt chapter 01
$ uktt heading 0101
$ uktt commodity 0101210000

# make a PDF
$ uktt pdf 01                   # specify a chapter_id
$ uktt pdf 'test'               # use the magic filename 'test' for a PDF smoketest
                                # which _doesn't_ hit the API

# 'goods nomenclatures' resources are only availab=le on `v2` of the API
$ uktt heading 0101 -g -a v2
$ uktt chapter 01 -g -a v2 
$ uktt section 1 --goods --api-version v2 # using long format options
```

## Development

While developing the gem, and for use outside of a Rails app, I found it useful to have a console:

```bash
$ bundle console
```

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` (or `bundle console` outside of a rails app) for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitLab at https://github.com/mcumcu/uktt/issues.

PRs can be submitted here https://github.com/mcumcu/uktt/pulls.

This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the `uktt` project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/uktt/blob/master/CODE_OF_CONDUCT.md).
