# frozen_string_literal: true

Undefined = Dry::Core::Constants::Undefined

RSpec.describe PromptSchema::SchemaCompiler do
  before do
    stub_const(
      "Types::Email", Dry::Types["strict.string"].meta(
        description: "An email address",
        example: "email@example.com"
      )
    )
  end

  it "compiles a simple schema AST to a hash" do
    schema = Dry::Schema.Params do
      required(:name).filled(:str?)
    end

    result = subject.call(schema.to_ast)

    expected = {
      name: {
        type: "string",
        required: true,
        nullable: false
      }
    }

    expect(result).to eq(expected)
  end

  it "compiles a type with metadata" do
    schema = Dry::Schema.Params do
      required(:email).value(type?: Types::Email)
    end

    result = subject.call(schema.to_ast)

    expected = {
      email: {
        type: "string",
        required: true,
        nullable: false,
        example: "email@example.com",
        description: "An email address"
      }
    }

    expect(result).to eq(expected)
  end
end
