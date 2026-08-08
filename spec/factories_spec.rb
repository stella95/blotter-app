require 'rails_helper'

# Guards against factories drifting out of sync with validations, which
# otherwise surfaces as confusing failures in unrelated specs.
RSpec.describe "factories" do
  FactoryBot.factories.map(&:name).each do |factory_name|
    it "builds a valid :#{factory_name}" do
      record = build(factory_name)

      expect(record).to be_valid, -> { "#{factory_name}: #{record.errors.full_messages.join(', ')}" }
    end
  end
end
