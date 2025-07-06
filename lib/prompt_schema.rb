# frozen_string_literal: true

require "debug"

require "dry/schema"
require "dry/types"
require "phlex"

require_relative "prompt_schema/version"
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
end
