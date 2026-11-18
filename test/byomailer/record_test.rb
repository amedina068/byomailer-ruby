require "test_helper"

class Byomailer::RecordTest < Byomailer::TestCase
  def setup
    @record = Byomailer::Record.new("email" => "ana@example.com", "tags" => [ { "name" => "VIP" } ], "list" => { "id" => 3 })
  end

  def test_reads_a_field_as_a_method_or_with_brackets
    assert_equal "ana@example.com", @record.email
    assert_equal "ana@example.com", @record[:email]
    assert_equal "ana@example.com", @record["email"]
  end

  def test_wraps_nested_hashes_and_arrays
    assert_equal 3, @record.list.id
    assert_equal "VIP", @record.tags.first.name
  end

  def test_an_unknown_field_raises_no_method_error
    assert_raises(NoMethodError) { @record.phone }
    assert_nil @record[:phone]
    refute_respond_to @record, :phone
  end

  def test_to_h_and_equality
    assert_equal "ana@example.com", @record.to_h["email"]
    assert_equal @record, Byomailer::Record.new(@record.to_h)
  end
end
