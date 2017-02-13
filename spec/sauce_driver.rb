require "selenium/webdriver"

module SauceDriver
  class << self

    def username
      ENV['SAUCE_USERNAME']
    end

    def access_key
      ENV['SAUCE_ACCESS_KEY']
    end

    def authentication
      "#{username}:#{access_key}"
    end

    def sauce_server
      'ondemand.saucelabs.com'
    end

    def sauce_port
      80
    end

    def endpoint
      "http://#{authentication}@#{sauce_server}:#{sauce_port}/wd/hub"
    end

    def environment_capabilities
      caps = Selenium::WebDriver::Remote::Capabilities.chrome
      browser = ENV['SAUCE_BROWSER']
      caps.version = ENV['SAUCE_VERSION']
      caps.platform = "Mac OS X 10.10"
      caps['tunnel_identifier'] = ENV['TRAVIS_JOB_NUMBER']

      if browser && caps.version && caps.platform && caps['tunnel_identifier']
        return {
          :browserName => browser,
          :version => caps.version,
          :platform => caps.platform,
          :tunnel_identifier => caps['tunnel_identifier']
        }
      end

      return nil
    end

    def desired_caps
      environment_capabilities
    end

  end
end