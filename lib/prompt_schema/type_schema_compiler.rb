# frozen_string_literal: true

module PromptSchema
  class TypeSchemaCompiler
    def self.call(ast) = new.call(ast)

    def call(ast)
      visit(ast)
    end

    private

    def visit(node)
      type, body = node
      send("visit_#{type}", body)
    end

    def visit_schema(node)
      keys, _options, _meta = node
      { keys: keys.to_h { visit(it) } }
    end

    def visit_key(node)
      name, _required, type_node = node
      [name, visit(type_node)]
    end

    def visit_nominal(node)
      klass, meta = node

      if klass.respond_to?(:to_ast)
        {
          keys: visit(klass.to_ast)
        }
      else
        {
          type: dry_type_name(klass),
          **filtered_meta(meta)
        }
      end
    end

    def visit_maybe(node)
      inner = visit(node)
      inner[:type] = "maybe.#{inner[:type]}"
      inner
    end

    def visit_hash(node)
      opts, _meta = node
      { keys: visit_schema([opts[:keys], {}, {}]) }
    end

    def visit_array(node)
      member, meta = node
      member_type = member.is_a?(Class) ? dry_type_name(member) : visit(member)[:type]
      {
        type: "array[#{member_type}]",
        **filtered_meta(meta)
      }
    end

    def visit_sum(node)
      *types, meta = node
      {
        type: types.map { |t| visit(t)[:type] }.join(" | "),
        **filtered_meta(meta)
      }
    end

    def visit_constructor(node)
      visit(node.first)
    end

    def visit_lax(node)
      visit(node)
    end

    def visit_enum(node)
      type, mapping = node
      {
        type: "enum(#{visit(type)[:type]})",
        values: mapping.values
      }
    end

    def visit_any(meta)
      {
        type: "any",
        **filtered_meta(meta)
      }
    end

    def visit_map(node)
      key_type, value_type, meta = node
      {
        type: "map[#{visit(key_type)[:type]} => #{visit(value_type)[:type]}]",
        **filtered_meta(meta)
      }
    end

    def visit_constrained(node)
      visit(node.first)
    end

    def dry_type_name(klass)
      Dry::Types.identifier(klass)&.to_s || klass.name || klass.to_s
    end

    def filtered_meta(meta)
      meta.reject { |k, _| %i[required maybe].include?(k) }
    end
  end
end
