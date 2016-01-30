module Net
  class IRC
    module Nicl
      module Ansi
        RESET = 0
        BOLD = 1
        DIM = 2
        UNDERSCORE = 4
        BLINK = 5
        REVERSE = 7
        HIDDEN = 8

        BLACK = 0
        RED = 1
        GREEN = 2
        YELLOW = 3
        BLUE = 4
        MAGENTA = 5
        CYAN = 6
        WHITE = 7

        def esc(*attrs)
          "\033[#{attrs.join(';')}m"
        end

        def fg(colour)
          30 + colour
        end

        def bg(colour)
          40 + colour
        end

        def highlight(text, *attrs)
          "#{esc(*attrs)}#{text}#{esc(RESET)}"
        end
      end
    end
  end
end
