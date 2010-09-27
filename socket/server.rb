require 'rubygems'
require 'em-websocket'
require 'em-mongo'

EventMachine.run {
  @channel = EM::Channel.new

  @db = EM::Mongo::Connection.new.db('streamcongress')
  @collection = @db.collection('activities')

  ids = []
  EM::add_periodic_timer(1) do
    
    @collection.find do |results|
      results.each do |result|
        unless ids.include?(result['_id'])
          @channel.push result["message"]
          ids << result['_id']
        end
      end
    end

  end

  EventMachine::WebSocket.start(:host => "localhost", :port => 8080, :debug => true) do |ws|

    ws.onopen do

      @channel.push "Websocket connected!"
      subscription = @channel.subscribe do |msg| 
        ws.send msg
      end
      ws.onclose do
        @channel.unsubscribe(subscription)
      end

    end
  end

  puts "Server started"
}