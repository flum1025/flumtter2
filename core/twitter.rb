require 'twitter'

module Flumtter
  class Twitter
    @@events = {}

    def self.on_event(event,&blk)
      @@events[event] ||= []
      @@events[event] << blk
    end

    def callback(event, object)
      return if !@@events[event]
      @@events[event].each do |c|
        c.call(object)
      end
    end

    attr_reader :rest, :stream, :thread, :name, :id

    def initialize(keys)
      @name = keys[:screen_name]
      @id = keys[:id]
      @rest = ::Twitter::REST::Client.new keys
      @stream = ::Twitter::Streaming::Client.new keys
      @queue = Queue.new
      @pause = false
    end

    def change(keys)
      kill
      @name = keys[:screen_name]
      @id = keys[:id]
      @rest = ::Twitter::REST::Client.new keys
      @stream = ::Twitter::Streaming::Client.new keys
    end

    def kill
      @thread.kill
      @ethread.kill
      @queue.clear
    end

    def stream(options={})
      puts "@#{@name}'s stream_start!"
      execute
      @thread = Thread.new do
        begin
          @stream.user(options) do |object|
            Window.update
            kind = case object
            when ::Twitter::Tweet
              :tweet
            when ::Twitter::Streaming::Event
              case object.name.to_s
              when "favorite"
                :favorite
              when "unfavorite"
                :unfavorite
              when "follow"
                :follow
              when "unfollow"
                :unfollow
              else
                :event
              end
            when ::Twitter::Streaming::FriendList
              :friendlist
            when ::Twitter::Streaming::DeletedTweet
              :deletedtweet
            when ::Twitter::DirectMessage
              :directmessage
            end
            @queue.push [kind, object]
          end
        rescue EOFError
          p :EOFError
          retry
        end
      end
    end

    def execute
      @ethread = Thread.new do
        loop do
          if @pause
            sleep 0.1
          else
            kind, object = @queue.pop
            callback(kind, [object,self])
          end
        end
      end
    end

    def pause
      @pause = true
    end

    def resume
      @pause = false
    end
  end
end