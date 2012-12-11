RSpec.configure do |config|  
  config.include Sorcery::TestHelpers::Rails
end

module Sorcery
  module TestHelpers
    module Rails
      def login_user_post(user, password)
        page.driver.post(user_sessions_url, { username: user, password: password}) 
      end
    end
  end
end