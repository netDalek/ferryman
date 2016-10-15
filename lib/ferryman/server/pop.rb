require 'active_support'
require 'active_support/core_ext/class'
require 'logger'

module Ferryman
  module Server
    class Pop < Base
      def receive(obj)
        args = @channels + [5]
        while true do
          ch, msg = @redis.blpop(*args)
          if msg
            logger.info "[Ferryman::PopServer] received #{msg} from #{ch}"
            process(msg, obj)
          end
        end
      end
    end
  end
end
