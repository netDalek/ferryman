require 'active_support'
require 'active_support/core_ext/class'
require 'logger'

module Ferryman
  module Server
    class Subscribe < Base
      def receive(obj)
        @redis.subscribe(*@channels) do |on|
          on.message do |ch, msg|
            logger.info "[Ferryman::SubscribeServer] received #{msg} from #{ch}"
            process(msg, obj)
          end
        end
      end
    end
  end
end
