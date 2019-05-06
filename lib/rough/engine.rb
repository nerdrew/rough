require_relative 'middleware'
require_relative 'base_controller'
require 'rails/engine'

module Rough

  class Engine < Rails::Engine

    initializer 'rough_engine.middleware', before: 'build_middleware_stack' do |app|
      app.middleware.use Rough::Middleware
    end

  end

end
