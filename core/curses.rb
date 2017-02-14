require 'dispel'
module Dispel
  class CloseWindow < StandardError; end
  class NoCommandError < StandardError; end

  class Window
    class << self
      def open(*args)
        win = Curses::Window.new(*args)
        win.keypad(true)
        yield win
      rescue CloseWindow
      ensure
        win.refresh
        win.close
      end

      def close
        raise CloseWindow
      end
    end
  end

  module Util
    def getstr(win)
      buf = ""
      x = win.curx
      loop do
        i = win.getch
        next unless i
        case input = Dispel::Keyboard.translate_key_to_code(i)
        when :"Ctrl+c"
          raise CloseWindow
        when :enter
          return buf
        when :escape
          raise CloseWindow
        when :left
          if win.curx > x
            win.setpos(win.cury, win.curx-1)
          end
        when :right
          if win.curx <= buf.size
            win.setpos(win.cury, win.curx+1)
          end
          # TODO: 文字移動して削除入力
        when :backspace
          buf.chop!
          while win.curx > x
            win.setpos(win.cury, win.curx-1)
            win.delch()
            win.insch(" ")
          end
          win.addstr(buf)
        when String
          input = case input.encoding.name
          when "UTF-8" then input
          when "ASCII-8BIT"
            require 'timeout'
            tmp = [input]
            begin
              Timeout.timeout(0.01) do
                loop do
                  tmp << Dispel::Keyboard.translate_key_to_code(win.getch)
                end
              end
              rescue Timeout::Error
            end
            tmp.join.force_encoding('utf-8')
          end
          buf << input
          win.setpos(win.cury, win.curx)
          win.addstr(input)
        else
          p input
        end
      end
    end
  end
end

module Flumtter
  sarastire 'core/windows'
end
