require "spec_helper"
require "ferryman"
require "pry"

describe "ferryman" do
  it "receive call and cast messages" do
    client = Ferryman::Client.new(Redis.new, "dd")
    server = Ferryman::Server.new(Redis.new, Redis.new, "dd")
    t = Thread.start(server) do |server|
      server.receive do |method, args|
        case method
        when :exit
          raise Ferryman::ExitError
        when :raise
          1.send(:no_method)
        when :sum
          args.first + args.last
        end
      end
    end
    sleep(0.1)

    expect(client.call(:sum, 1, 2)).to eql(3)
    expect{ client.call(:raise) }.to raise_error(Ferryman::Error)
    client.cast(:exit)
    t.join
  end
end
