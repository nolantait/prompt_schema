# frozen_string_literal: true

require "debug"

require "dry/schema"
require "dry/types"
require "phlex"

require_relative "prompt_schema/version"
require_relative "prompt_schema/type_schema_compiler"
require_relative "prompt_schema/schema_compiler"
require_relative "prompt_schema/schema"
require_relative "prompt_schema/prompt"

module PromptSchema
  class Error < StandardError; end

  # Defines a schema using Dry::Schema and returns a Schema instance.
  #
  # @example
  # PromptSchema.define do
  #  required(:name).filled(:string)
  # end
  #
  # @return [PromptSchema::Schema]
  def self.define(&)
    dry_schema = Dry::Schema.JSON(&)
    Schema.new(dry_schema)
  end

  # Compiles a schema into a format suitable for generating prompts.
  # This is a wrapper around `PromptSchema::SchemaCompiler.call`.
  #
  # @example
  # PromptSchema.compile(schema)
  #
  # @param schema [Dry::Schema::Schema] The schema to compile.
  # @return [Hash] The compiled schema as a hash.
  def self.compile(schema)
    SchemaCompiler.call(schema)
  end
end
