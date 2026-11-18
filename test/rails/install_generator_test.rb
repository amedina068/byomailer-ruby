require "rails_helper"
require "rails/generators/test_case"
require "generators/byomailer/install/install_generator"

class Byomailer::InstallGeneratorTest < Rails::Generators::TestCase
  tests Byomailer::Generators::InstallGenerator
  destination File.expand_path("../../tmp/generator", __dir__)
  setup :prepare_destination

  test "writes the initializer" do
    output = run_generator

    assert_file "config/initializers/byomailer.rb" do |initializer|
      assert_match "Byomailer.configure do |config|", initializer
      assert_match "Rails.application.credentials.byomailer", initializer
    end
    assert_match "bin/rails credentials:edit", output
  end

  test "the initializer is valid Ruby" do
    run_generator

    assert RubyVM::InstructionSequence.compile_file(File.join(destination_root, "config/initializers/byomailer.rb"))
  end
end
