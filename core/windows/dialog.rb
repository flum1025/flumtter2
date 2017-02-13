module Flumtter
  class Dialog
    include Dispel::Util

    class Command
      attr_reader :command
      def initialize(command, blk)
        @command = command
        @blk = blk
      end

      def call(*args)
        @blk.call(*args)
      end
    end

    def initialize(title, body, 
                   hight=body.each_line.to_a.size,
                   width=body.each_line.max_by{|str|str.size}.size+2)
      @title = title
      @body = body
      @hight = hight + 8
      @width = width
      @commands = []
    end

    def command(command, &blk)
      @commands << Command.new(command, blk)
    end

    def call(str)
      call_size = 0
      @commands.each do |command|
        if m = str.match(command.command)
          call_size += 1
          command.call(m)
        end
      end
      call_size
    end

    def show(recall=false, help=true)
      call_size = Dispel::Screen.open do |screen|
        Dispel::Window.open(@hight, @width, 0, 0) do |win|
          win.box(?|,?-,?*)
          win.setpos(win.cury+2, win.curx+1)
          win.addstr @title.title
          win.setpos(win.cury+1, 1)
          win.addstr "¯"*(@title.title.size+2)

          @body.each_line do |line|
            win.setpos(win.cury+1, 1)
            win.addstr line.chomp
          end

          if block_given?
            yield win
          else
            if help
              win.setpos(win.cury+2, 1)
              win.addstr "help: ?".rjust(win.maxx - 2)
              win.setpos(win.cury+1, 1)
            end
            call getstr(win)
          end
        end
      end
      show(recall) if recall && !call_size.nil? && call_size.zero?
    end
  end
end