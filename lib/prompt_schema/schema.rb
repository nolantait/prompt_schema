# frozen_string_literal: true

module PromptSchema
  class Schema
    def initialize(dry_schema)
      @dry_schema = dry_schema
    end

    def prompt
      Prompt.call(@dry_schema)
    end
  end
end
