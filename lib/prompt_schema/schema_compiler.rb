# frozen_string_literal: true

module PromptSchema
  # Compiles a Dry::Schema schema into a hash representation that can be used
  # to generate prompts for LLMs.
  class SchemaCompiler # rubocop:disable Metrics/ClassLength
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

    # @param schema [Dry::Schema::Schema] The schema to compile.
    def initialize(schema)
      @schema = schema
      @type_schema = TypeSchemaCompiler.call(schema.type_schema.to_ast)
      @keys = EMPTY_HASH.dup
    end

    # @return [Hash] The compiled schema as a hash.
    def to_h
      { keys: keys }
    end

    # @return [Hash] The compiled schema as a hash
    def call
      visit(@schema.to_ast)
      to_h
    end

    # @param node [Array] The AST node to visit.
    # @param opts [Hash] Options for visiting the node.
    # @return [void]
    def visit(node, **)
      meth, rest = node
      public_send(:"visit_#{meth}", rest, **)
    end

    # @param node [Array] The AST node to visit.
    # @param opts [Hash] Options for visiting the node.
    # @return [void]
    def visit_set(node, **opts)
      key = opts[:key]
      target = key ? self.class.new(@schema) : self

      node.each { |child| target.visit(child, **opts.except(:member)) }

      return unless key

      target_info = opts[:member] ? { member: target.to_h } : target.to_h
      type = opts[:member] ? "array" : "hash"
      data = { **keys[key], type:, **target_info }

      keys.update(key => data)
    end

    # @param node [Array] The AST node to visit.
    # @param opts [Hash] Options for visiting the node.
    # @return [void]
    def visit_and(node, **)
      left, right = node

      visit(left, **)
      visit(right, **)
    end

    # @param node [Array] The AST node to visit.
    # @param opts [Hash] Options for visiting the node.
    # @return [void]
    def visit_implication(node, **)
      case node
      in [:not, [:predicate, [:nil?, _]]], el
        visit(el, **, nullable: true)
      else
        node.each do |el|
          visit(el, **, required: false)
        end
      end
    end

    # @param node [Array] The AST node to visit.
    # @param opts [Hash] Options for visiting the node.
    # @return [void]
    def visit_each(node, **opts)
      opts[:key_path] ||= []
      opts[:key_path] << :items

      visit(node, **opts, member: true)
    end

    # @param node [Array] The AST node to visit.
    # @param opts [Hash] Options for visiting the node.
    # @return [void]
    def visit_key(node, **opts)
      name, rest = node
      opts[:key_path] ||= []
      opts[:key_path] << name

      visit(rest, **opts, key: name, required: true)
      opts[:key_path].pop
    end

    # @param node [Array] The AST node to visit.
    # @param opts [Hash] Options for visiting the node.
    # @return [void]
    def visit_predicate(node, **opts)
      name, rest = node
      key = opts[:key]

      case name
      when :key?
        visit_predicate_key(rest, **opts)
      when :type?
        visit_predicate_type(rest, **opts)
      else
        visit_predicate_base_type(name, key, **opts)
      end
    end

    # @param name [Symbol] The name of the predicate.
    # @param key [Symbol] The key to assign the type to.
    # @param opts [Hash] Additional options for assigning the type.
    # @return [void]
    def visit_predicate_base_type(name, key, **opts)
      type = PREDICATE_TO_TYPE[name]
      return unless type

      assign_type(
        key,
        type,
        **opts,
        nullable: opts.fetch(:nullable, false)
      )
    end

    # @param node [Array] The AST node to visit.
    # @param opts [Hash] Options for visiting the node.
    # @return [void]
    def visit_predicate_key(node, **opts)
      (_, name), = node
      keys[name] ||= {}
      keys[name] = { **keys[name], required: opts.fetch(:required, true) }
    end

    # @param node [Array] The AST node to visit.
    # @param opts [Hash] Options for visiting the node.
    # @return [void]
    def visit_predicate_type(node, **opts)
      (_type, type_class), _input = node
      key = opts[:key]

      if type_class.is_a?(Dry::Types::Type)
        keys[key].merge!(type_class.meta)

        assign_type(
          key,
          type_class.name.downcase,
          **opts,
          nullable: opts.fetch(:nullable, false)
        )
      else
        visit(type_class.to_ast, **opts, key: key, member: true)
      end
    end

    # @param key [Symbol] The key to assign the type to.
    # @param type [String] The type to assign to the key.
    # @param opts [Hash] Additional options for assigning the type.
    # @return [void]
    def assign_type(key, type, **opts)
      if keys.dig(key, :type)
        keys[key][:member] = type
      else
        keys[key][:type] = type
        keys[key][:nullable] = opts.fetch(:nullable, false)
      end

      meta = @type_schema.dig(*opts[:key_path])
      keys[key].merge!(meta.slice(:description, :example)) if meta
    end
  end
end
