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
  end

  it "receive call and cast messages" do
    client = Ferryman::Client.new(Redis.new, "dd")
    server = Ferryman::Server.new(Redis.new, "dd")
    t = Thread.start(server) do |server|
      server.receive(TTT.new)
    end
    sleep(0.1)

    expect(client.call(:sum, 1, 2)).to eql(3)
    expect{ client.call(:raise) }.to raise_error(Ferryman::Error)
    t.kill
  end
end
