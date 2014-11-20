require 'securerandom'
require 'redis'
require "json-rpc-objects/request"
require "json-rpc-objects/response"

require "ferryman/client"
require "ferryman/server"
require "ferryman/error"
require "ferryman/handler"

module Ferryman
  class ExitError < RuntimeError; end
end

