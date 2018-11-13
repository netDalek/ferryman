require "spec_helper"
require "ferryman"
require "pry"

describe "ferryman" do
  class TTT
    def raise
      1.send(:no_method)
    end
    def sum(a, b)
      a + b
    end
    def long
      sleep(2)
    end
  end

  it "receive call and cast messages" do
    client = Ferryman::Client.new(Redis.new, "dd", 1)
    server = Ferryman::Server::Subscribe.new(Redis.new, "dd")
    t = Thread.start(server) do |server|
      begin
        server.receive(TTT.new)
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
    end
    sleep(10)

    expect(client.call(:sum, 1, 2).publish.result).to eql(3)
    expect(client.cast(:sum, 1, 2).publish).to eql(1)
    expect(client.call(:sum, 1, 2).publish.results).to eql([3])
    message = "RPC to redis://127.0.0.1:6379/0 channel dd method raise with arguments [] failed with error 'undefined method `no_method' for 1:Integer'"
    expect{ client.call(:raise).publish.result }.to raise_error(Ferryman::Error, message)
    exception = begin
                  client.call(:raise).publish.result
                rescue => e
                  e
                end
    expect(exception.backtrace.first).to match(/ferryman_spec/)
    expect{ client.call(:long).publish.results }.to raise_error(Timeout::Error)
    t.kill
  end

  it "receive call and cast messages" do
    client = Ferryman::Client.new(Redis.new, "dd", 1)
    server = Ferryman::Server::Pop.new(Redis.new, "dd")
    t = Thread.start(server) do |server|
      begin
        server.receive(TTT.new)
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
    end
    sleep(10)

    expect(client.call(:sum, 1, 2).push.order).to eql(1)
    expect(client.call(:sum, 1, 2).push.result).to eql(3)
    expect(client.cast(:sum, 1, 2).push).to eql(1)
    expect(client.call(:sum, 1, 2).push.results).to eql([3])
    message = "RPC to redis://127.0.0.1:6379/0 channel dd method raise with arguments [] failed with error 'undefined method `no_method' for 1:Integer'"
    expect{ client.call(:raise).push.result }.to raise_error(Ferryman::Error, message)
    exception = begin
                  client.call(:raise).push.result
                rescue => e
                  e
                end
    expect(exception.backtrace.first).to match(/ferryman_spec/)
    expect{ client.call(:long).push.result }.to raise_error(Timeout::Error)
    t.kill
  end
end
