# frozen_string_literal: true

require "debug"

require "dry/schema"
require "dry/types"

require_relative "prompt_schema/version"
require_relative "prompt_schema/schema_compiler"

module PromptSchema
  class Error < StandardError; end
end
