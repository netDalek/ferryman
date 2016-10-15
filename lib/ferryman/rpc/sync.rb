module Ferryman
  module Rpc
    class Sync < Base
      def initialize(*arguments)
        super(*arguments)
      end

      def publish
        servers_count = super()
        Result.new(self, redis, key, timeout, servers_count)
      end

      def push
        order = super()
        Result.new(self, redis, key, timeout, 1, order)
      end

      private

      def key
        @key ||= SecureRandom.hex(16)[0..7]
      end
    end
  end
end
