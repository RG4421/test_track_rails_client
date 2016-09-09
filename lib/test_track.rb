require 'public_suffix'
require 'mixpanel-ruby'
require 'resolv'
require 'faraday_middleware'
require 'her'
require 'request_store'

module TestTrack
  module_function

  SERVER_ERRORS = [Faraday::TimeoutError, Her::Errors::RemoteServerError].freeze

  mattr_accessor :enabled_override

  class << self
    def analytics
      @analytics ||= wrapper(mixpanel)
    end

    def analytics=(client)
      @analytics = client.is_a?(Analytics::SafeWrapper) ? client : wrapper(client)
    end

    private

    def wrapper(client)
      Analytics::SafeWrapper.new(client)
    end

    def mixpanel
      Analytics::MixpanelClient.new
    end
  end

  def update_config
    yield(ConfigUpdater.new)
  end

  def url
    return nil unless private_url
    full_uri = URI.parse(private_url)
    full_uri.user = nil
    full_uri.password = nil
    full_uri.to_s
  end

  def private_url
    ENV['TEST_TRACK_API_URL']
  end

  def enabled?
    enabled_override.nil? ? !Rails.env.test? : enabled_override
  end

  def fully_qualified_cookie_domain_enabled?
    ENV['TEST_TRACK_FULLY_QUALIFIED_COOKIE_DOMAIN_ENABLED'] == '1'
  end
end
