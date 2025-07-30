# frozen_string_literal: true

module PromptSchema
  # Represents a Dry::Schema schema, providing methods to access its
  # properties and to generate prompts based on the schema.
  class Schema
    attr_reader :dry_schema

    def initialize(dry_schema)
      @dry_schema = dry_schema
    end

    def [](...) = @dry_schema.[](...)
    def call(...) = @dry_schema.call(...)

    def prompt
      Prompt.call(@dry_schema)
    end
  end
end
