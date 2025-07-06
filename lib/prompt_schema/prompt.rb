# frozen_string_literal: true

module PromptSchema
  class Prompt < Phlex::HTML
    def initialize(schema)
      @compiled = SchemaCompiler.call(schema.to_ast)
      @indentation = 0
    end

    def view_template
      text "Answer in JSON using this schema:"
      text "{"
      @indentation += 2
      @compiled[:keys].each do |key, info|
        text("#{key}: ", newline: false)

        if info[:type] == "array"
          text "["
          @indentation += 2
          text info[:member][:type] if info[:member]
          @indentation -= 2
          text "]"
        else
          text(info[:type], newline: false, indent: false)
        end

        text(",", indent: false)
      end
      @indentation -= 2

      text("}", newline: false)
    end

    private

    def text(content, newline: true, indent: true)
      plain " " * @indentation if indent
      plain content
      plain "\n" if newline
    end
  end
end
