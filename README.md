# PromptSchema

This is a library to give you [BAML](https://github.com/BoundaryML/baml) style
JSON schemas that you can feed to an LLM using your existing
[`dry-schema`](https://github.com/dry-rb/dry-schema) with
annotated types.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add prompt_schema
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install prompt_schema
```

## Usage

Schemas are defined as a class that wraps a regular `dry-schema`:

```ruby
schema = Dry::Schema.JSON do
  required(:user).hash do
    required(:email).maybe(:string)
  end
end

prompt_schema = PromptSchema::Schema.new(schema)
```

For convenience you can use `define` to have this wrapping be done for you:

```ruby
schema = PromptSchema.define do
  required(:user).hash do
    required(:email).maybe(:string)
  end
end

schema.is_a?(PromptSchema::Schema) #=> true
schema.dry_schema.is_a?(Dry::Schema) #=> true

result = schema.call({ user: { email: "email@example.com" }})
result.success? #=> true
```

Using this schema we can print a ready to go prompt.

```ruby
schema.prompt
```

Which would return a string of a BAML style prompt:

```
Answer in JSON using this schema:
{
  user: {
    email: string or null,
  },
}
```

To get the descriptions we can annotate our own types using `dry-types`:

```ruby
module Types
  include Dry.Types()

  Email = Types::String.meta(
    description: "An email address",
    example: "email@example.com"
  )
end

schema = PromptSchema.define do
  required(:user).hash do
    required(:email).maybe(Types::Email)
  end
end

schema.prompt
```

Which would now annotate the field

```
Answer in JSON using this schema:
{
  user: {
    // An email address
    // @example email@example.com
    email: string or null,
  },
}
```

This can be useful to get the best parts of BAML in a ruby native way.

## How it works

All `Dry::Schema` objects have an Abstract Syntax Tree (AST) that we can tap
into to build another representation.

We turn the dry schema AST (and its corresponding type schema AST) into
a structure that looks like this:

```ruby
schema = Dry::Schema.Params do
  required(:user).hash do
    required(:email).value(Types::Email)
  end
end

compiled = PromptSchema.compile(schema)

expected = {
  keys: {
    user: {
      type: "hash",
      required: true,
      nullable: false,
      keys: {
        email: {
          type: "string",
          required: true,
          nullable: false,
          example: "email@example.com",
          description: "An email address"
        }
      }
    }
  }
}

compiled == expected #=> true
```

Then we use a renderer to take this compiled schema and output a string that can
be used as part of a prompt.

Rendering of the prompt is handled through a Phlex component. You could take
this same representation and write your own version.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and the created tag, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nolantait/prompt_schema.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
