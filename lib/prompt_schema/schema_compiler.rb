# frozen_string_literal: true

module PromptSchema
  class SchemaCompiler
    EMPTY_HASH = {}.freeze

    PREDICATE_TO_TYPE = {
      array?: "array",
      bool?: "bool",
      date?: "date",
      date_time?: "date_time",
      decimal?: "float",
      float?: "float",
      hash?: "hash",
      int?: "integer",
      nil?: "nil",
      str?: "string",
      time?: "time"
    }.freeze

    attr_reader :keys

    def self.call(schema) = new(schema).call

    def initialize(schema)
      @schema = schema
      @keys = EMPTY_HASH.dup
    end

    def to_h
      { keys: keys }
    end

    def call
      visit(@schema.to_ast)
      to_h
    end

    def visit(node, opts = EMPTY_HASH)
      meth, rest = node
      public_send(:"visit_#{meth}", rest, opts)
    end

    def visit_set(node, opts = EMPTY_HASH)
      target = (key = opts[:key]) ? self.class.new(@schema) : self

      node.each { |child| target.visit(child, opts) }

      return unless key

      target_info = opts[:member] ? { member: target.to_h } : target.to_h
      type = opts[:member] ? "array" : "hash"

      keys.update(key => { **keys[key], type: type, **target_info })
    end

    def visit_and(node, opts = EMPTY_HASH)
      left, right = node

      visit(left, opts)
      visit(right, opts)
    end

    def visit_implication(node, opts = EMPTY_HASH)
      case node
      in [:not, [:predicate, [:nil?, _]]], el
        visit(el, { **opts, nullable: true })
      else
        node.each do |el|
          visit(el, { **opts, required: false })
        end
      end
    end

    def visit_each(node, opts = EMPTY_HASH)
      visit(node, { **opts, member: true })
    end

    def visit_key(node, opts = EMPTY_HASH)
      name, rest = node
      visit(rest, { **opts, key: name, required: true })
    end

    def visit_predicate(node, opts = EMPTY_HASH)
      name, rest = node
      key = opts[:key]

      case name
      when :key?
        visit_predicate_key(rest, opts)
      when :type?
        visit_predicate_type(rest, opts)
      else
        visit_predicate_base_type(name, key, opts)
      end
    end

    def visit_predicate_base_type(name, key, opts = EMPTY_HASH)
      type = PREDICATE_TO_TYPE[name]
      nullable = opts.fetch(:nullable, false)
      assign_type(key, type, nullable) if type
    end

    def visit_predicate_key(node, opts = EMPTY_HASH)
      (_, name), = node
      keys[name] = { required: opts.fetch(:required, true) }
    end

    def visit_predicate_type(node, opts = EMPTY_HASH)
      (_type, type_class), _input = node
      key = opts[:key]

      if type_class.is_a?(Dry::Types::Type)
        keys[key].merge!(type_class.meta)

        assign_type(
          key,
          type_class.name.downcase,
          opts.fetch(:nullable, false)
        )
      else
        visit(type_class.to_ast, { **opts, key: key, member: true })
      end
    end

    def assign_type(key, type, nullable)
      if keys.dig(key, :type)
        keys[key][:member] = type
      else
        keys[key][:type] = type
        keys[key][:nullable] = nullable
      end
    end
  end
end
