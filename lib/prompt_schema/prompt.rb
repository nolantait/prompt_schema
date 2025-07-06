# frozen_string_literal: true

module PromptSchema
  class Prompt < Phlex::HTML
    def initialize(schema)
      @compiled = SchemaCompiler.call(schema.to_ast)
      @indentation = 0
    end

    def view_template
      text "Answer in JSON using this schema:"
      with_nested("{", "}") do
        @compiled[:keys].each do |key, info|
          item(key, info)
        end
      end
    end

    private

    def item(key, info)
      comment info[:description] if info[:description]
      example info[:example] if info[:example]
      text("#{key}: ", newline: false)

      case info[:type]
      when "array"
        with_nested("[", "]") do
          text info[:member][:type] if info[:member]
        end
      when "hash"
        with_nested("{", "}") do
          text info[:member][:type] if info[:member]
        end
      else
        types = [info[:type], ("null" if info[:nullable])]

        text(
          types.compact.join(" or "),
          newline: false,
          indent: false
        )
      end

      text(",", indent: false)
    end

    def with_nested(opening, closing, &)
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
      plain content
      plain "\n" if newline
    end
  end
end
