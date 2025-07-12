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
      keys.to_h { |key| visit(key) }
    end

    def visit_key(node)
      name, required, type_node = node
      type_info = visit(type_node)
      [name, { required: required, **type_info }]
    end

    def visit_nominal(node)
      klass, meta = node
      {
        type: dry_type_name(klass),
        **meta
      }
    end

    def visit_maybe(node)
      inner = visit(node)
      inner[:type] = "maybe.#{inner[:type]}"
      inner
    end

    def visit_array(node)
      member_node, meta = node

      member_info = if member_node.is_a?(Array) && member_node.first == :schema
        visit_schema(member_node.last)
      elsif member_node.is_a?(Class)
        { type: dry_type_name(member_node) }
      else
        visit(member_node)
      end

      {
        type: "array",
        items: member_info,
        **meta
      }
    end

    def visit_sum(node)
      *types, meta = node
      type_names = types.map { |t| visit(t)[:type] }
      {
        type: type_names.join(" | "),
        **meta
      }
    end

    def visit_map(node)
      key_type, value_type, meta = node
      {
        type: "map[#{visit(key_type)[:type]} => #{visit(value_type)[:type]}]",
        **meta
      }
    end

    def visit_constrained(node)
      base_type, rule = node
      base = visit(base_type)
      base[:rule] = rule
      base
    end

    def visit_constructor(node)
      base_type, _fn = node
      visit(base_type)
    end

    def visit_lax(node)
      visit(node)
    end

    def visit_enum(node)
      type_node, mapping = node
      {
        type: "enum(#{visit(type_node)[:type]})",
        values: mapping.values
      }
    end

    def visit_any(meta)
      {
        type: "any",
        **meta
      }
    end

    def dry_type_name(klass)
      Dry::Types.identifier(klass) || klass.name || klass.to_s
    end
  end
end
