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
    server = Ferryman::Server.new(Redis.new, "dd")
    t = Thread.start(server) do |server|
      begin
        server.receive(TTT.new)
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
    end
    sleep(10)

    expect(client.call(:sum, 1, 2)).to eql(3)
    expect(client.cast(:sum, 1, 2)).to eql(1)
    expect(client.multicall(:sum, 1, 2)).to eql([3])
    expect{ client.call(:raise) }.to raise_error(Ferryman::Error, "undefined method `no_method' for 1:Fixnum")
    exception = begin
                  client.call(:raise)
                rescue => e
                  e
                end
    expect(exception.backtrace.first).to match(/ferryman_spec/)
    expect{ client.call(:long) }.to raise_error(Timeout::Error)
    t.kill
  end
end
