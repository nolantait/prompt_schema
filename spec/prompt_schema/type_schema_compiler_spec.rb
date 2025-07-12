# frozen_string_literal: true

RSpec.describe PromptSchema::TypeSchemaCompiler do
  it "returns a hash of metadata" do
    schema = Dry::Schema.Params do
      required(:name).filled(Dry::Types["nominal.string"].meta(description: "The name of the person"))
      required(:address).hash do
        required(:street).filled(Dry::Types["nominal.string"].meta(something: "Something", description: "Street address"))
      end
    end

    result = subject.call(schema.type_schema.to_ast)

    expect(result).to eq(
      {
        keys: {
          name: {
            type: "string",
            description: "The name of the person"
          },
          address: {
            keys: {
              street: {
                type: "string",
                description: "Street address",
                something: "Something"
              }
            }
          }
        }
      }
    )
  end
end
