module Net
  class IRC
    module Nicl
      module Prompt
        begin
          require 'termios'
          # real implementation for toggling echo
          def echo(on = true)
            oldt = Termios.tcgetattr(STDIN)

            newt = oldt.dup
            if on
              newt.lflag |= Termios::ECHO
            else
              newt.lflag &= ~Termios::ECHO
            end
            Termios.tcsetattr(STDIN, Termios::TCSANOW, newt)

            # if no block is provided, return the original echo setting
            return (oldt.lflag & Termios::ECHO) == Termios::ECHO unless block_given?

            # otherwise yield to the block and restore the original echo setting
            yield

          ensure
            Termios.tcsetattr(STDIN, Termios::TCSANOW, oldt)
          end
        rescue LoadError
          STDERR.puts 'WARNING: Termios not available.'

          # minimal stub in case Termios is not installed
          def echo(_on = true) # rubocop:disable Lint/DuplicateMethods
            return true unless block_given?
            yield
          end
        end

        def prompt(text, hidden = false)
          echo(!hidden) do
            print text
            line = STDIN.readline.chomp
            print "\n" if hidden
            line
          end
        end
      end
    end
  end
end
