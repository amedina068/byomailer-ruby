require "test_helper"

class Byomailer::ConfigurationTest < Byomailer::TestCase
  def test_defaults
    config = Byomailer::Configuration.new

    assert_equal 30, config.timeout
    assert_equal 2, config.max_retries
  end

  def test_falls_back_to_the_environment
    with_env("BYOMAILER_URL" => URL, "BYOMAILER_TOKEN" => TOKEN, "BYOMAILER_WEBHOOK_SECRET" => "whsec_env") do
      config = Byomailer::Configuration.new

      assert_equal URL, config.url
      assert_equal TOKEN, config.token
      assert_equal "whsec_env", config.webhook_secret
    end
  end

  def test_a_set_value_wins_over_the_environment
    with_env("BYOMAILER_URL" => "https://other.example.com") do
      config = Byomailer::Configuration.new
      config.url = URL

      assert_equal URL, config.url
    end
  end

  def test_merge_copies_only_the_known_keys
    config = Byomailer::Configuration.new.merge!(url: URL, token: TOKEN, unknown: "x")

    assert_equal({ url: URL, token: TOKEN, timeout: 30, max_retries: 2 }, config.to_h)
  end

  def test_inspect_hides_the_token_and_the_secret
    config = Byomailer::Configuration.new.merge!(token: TOKEN, webhook_secret: "whsec_secret")

    refute_includes config.inspect, TOKEN
    refute_includes config.inspect, "whsec_secret"
  end

  private
    def with_env(values)
      saved = values.keys.to_h { |key| [ key, ENV[key] ] }
      values.each { |key, value| ENV[key] = value }
      yield
    ensure
      saved.each { |key, value| ENV[key] = value }
    end
end
