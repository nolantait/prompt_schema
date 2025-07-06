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
            text(info[:type], newline: false, indent: false)
          end

          text(",", indent: false)
        end
      end
    end

    private

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

    def text(content, newline: true, indent: true)
      plain " " * @indentation if indent
      plain content
      plain "\n" if newline
    end
  end
end
