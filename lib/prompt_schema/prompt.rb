# frozen_string_literal: true

module PromptSchema
  class Prompt < Phlex::HTML
    def initialize(schema)
      @compiled = SchemaCompiler.call(schema.to_ast)
      @indentation = 0
    end

    def view_template
      text "Answer in JSON using this schema:"
      render_structure(@compiled[:keys])
    end

    private

    def render_structure(keys)
      inside("{", "}") do
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

    def handle_type(key, info)
      case info[:type]
      when "array"
        inside("#{key}: [", "],") do
          render_structure(info[:keys])
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
      plain content
      plain "\n" if newline
    end
  end
end
