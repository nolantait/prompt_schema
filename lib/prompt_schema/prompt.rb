# frozen_string_literal: true

module PromptSchema
  # Generates a prompt for an LLM based on a compiled schema.
  class Prompt < Phlex::HTML
    # @param schema [Hash] The compiled schema to generate the prompt for.
    #   This should be the output of `PromptSchema::SchemaCompiler.call`.
    # @example
    #   PromptSchema::Prompt.new(schema).call
    # @return [String] The generated prompt.
    def initialize(schema)
      @compiled = SchemaCompiler.call(schema)
      @indentation = 0
    end

    def view_template
      text "Answer in JSON using this schema:"
      render_structure(@compiled[:keys])
    end

    private

    def render_structure(keys, nullable: false, nested: false)
      closing = [
        "}",
        (" or null" if nullable),
        ("," if nested)
      ].compact.join

      inside("{", closing) do
        render_keys(keys)
      end
    end

    def render_keys(keys)
      keys.each do |key, info|
        item(key, info)
      end
    end

    def item(key, info)
      comment info[:description] if info[:description]
      example info[:example] if info[:example]
      handle_type(key, info)
    end

    def handle_type(key, info) # rubocop:disable Metrics/AbcSize
      case info[:type]
      when "array"
        if info[:member].is_a?(Hash)
          inside("#{key}: [", "],") do
            render_structure(
              info[:member][:keys],
              nullable: info[:nullable],
              nested: true
            )
          end
        else
          text("#{key}: #{info[:member]}[]")
        end
      when "hash"
        inside("#{key}: {", "},") do
          render_keys(info[:keys])
        end
      else
        text("#{key}: ", newline: false)

        types = [info[:type], ("null" if info[:nullable])]

        text(
          types.compact.join(" or "),
          newline: false,
          indent: false
        )

        text(",", indent: false)
      end
    end

    def inside(opening, closing, &)
      text opening
      with_indentation(&)
      text closing
    end

    def with_indentation
      @indentation += 2
      yield
      @indentation -= 2
    end

    def comment(content, **)
      text("// #{content}", **)
    end

    def example(content, **)
      comment("@example #{content}", **)
    end

    def text(content, newline: true, indent: true)
      plain " " * @indentation if indent
      raw safe(content)
      plain "\n" if newline
    end
  end
end
