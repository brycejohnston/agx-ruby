# agX Platform API Client

[![Gem Version](http://img.shields.io/gem/v/agx.svg)][gem]

[gem]: https://rubygems.org/gems/agx

Ruby client for accessing Proagrica's [agX Platform APIs](http://www.agxplatform.com/agx-apis/).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'agx'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install agx

## Usage

### agX Content API

Setup agX Content Client (OAuth 2 Client Credentials Flow)
```ruby
@agx_content_client = Agx::Content::Client.new(
  client_id: "your_client_id",
  client_secret: "your_client_secret",
  version: "v1"  # optional
  prod: true # optional, false for QA
)
```

Make get requests for Content API resources
```ruby
# @agx_content_client.get("ResourceName", params_hash)
# => 'parsed_json_response_body'

crops = @agx_content_client.get("Crop")

# Passing in publishDate as param
weeds = @agx_content_client.get("Weed", {publishDate: date.to_s})
```

### agX Sync API

Setup agX Sync Client (OAuth 2.0 / OpenID Connect 1.0 Authorization Code Flow)

***This requires that you have already previously authenticated and authorized
a user to agX with required scopes through the authorization code grant flow process
and have persisted their sync ID, access token, refresh token, and access token
expiration timestamp.***

```ruby
@agx_sync_client = Agx::Sync::Client.new(
  client_id: "your_client_id",
  client_secret: "your_client_secret",
  version: "v4",  # optional
  sync_id: "agx_user_sync_id",
  access_token: "agx_user_agx_token",
  refresh_token: "agx_user_refresh_token",
  token_expires_at: "access_token_expiration_timestamp",
  transaction_id: "agx_user_previous_transaction_id", # optional
  prod: true # optional, false for QA
)
```

Initiate a sync transaction, make Sync API requests, and end transaction

```ruby
# To make calls without starting a transaction for resources that don't
# require it, use the get_nt method
# @agx_sync_client.get_nt("Resource", start_time)
# => 'parsed_json_response_body'
growers = @agx_sync_client.get_nt("Grower")

# To make calls that require transactions (sync locking), call start_transaction
# and then use the get method to call for the resource. You should persist
# transaction ID per user until transaction is successfully ended by call
# to end_transaction
transaction_id = @agx_sync_client.start_transaction

# @agx_sync_client.get("Resource", start_time)
# => 'parsed_json_response_body'
growers = @agx_sync_client.get("Grower")

# Get all farms accessible for a grower
farms = @agx_sync_client.get("Grower/#{grower.guid}/Farm")

# Get all server changes on farms accessible for a grower since start_time
farms = @agx_sync_client.get("Grower/#{grower.guid}/Farm", last_sync_date.to_s)

# Put (insert) a new Grower
now = Time.now.utc
new_grower = {
  "SyncID": @agx_sync_client.sync_id,
  "ID": SecureRandom.uuid,
  "Name": "MYNEWGROWER",
  "ModifiedOn": now,
  "CreatedOn": now,
  "CreatorID": @agx_sync_client.sync_id,
  "EditorID": @agx_sync_client.sync_id,
  "SchemaVersion": "4.0"
}

@client.put("Grower", new_grower.to_json)

# etc...

@agx_sync_client.end_transaction

# clear the persisted transaction ID for user after ending sync transaction
user_transaction_id = nil
```

### agX Pictures API

*Note: The pictures API client implementation still needs more work.*

Setup agX Pictures Client

```ruby
@agx_pictures_client = Agx::Pictures::Client.new(
  client_id: "your_client_id",
  client_secret: "your_client_secret",
  version: "v1",  # optional
  sync_id: "agx_user_sync_id",
  access_token: "agx_user_agx_token",
  refresh_token: "agx_user_refresh_token",
  token_expires_at: "access_token_expiration_timestamp",
  filepath: "/path/to/pictures/",
  prod: true # optional, false for QA
)
```

Make get requests for Pictures API images and metadata

***Currently only get requests are supported***
```ruby

# Get metadata
image_meta = @agx_pictures_client.get_metadata("661ee0c0-0cbc-4a7b-be39-1a9de49acc86")

# Get image and save to {filepath}/{sync_id}_{picture_id}.jpeg
image = @agx_pictures_client.get("661ee0c0-0cbc-4a7b-be39-1a9de49acc86")
# => "/path/to/pictures/7_661ee0c0-0cbc-4a7b-be39-1a9de49acc86.jpeg"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment. To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/beaorn/agx-ruby.


## License

The gem is available as open source under the terms of the MIT License (see [LICENSE.txt](https://github.com/beaorn/agx-ruby/blob/master/LICENSE.txt))

[agX](http://www.agxplatform.com/) is a registered trademark of [Proagrica](http://www.proagrica.com).
