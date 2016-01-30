require 'net/irc/ctcp'

module Net
  class IRC
    class CTCPAction < CTCP
      attr_accessor :text

      def initialize(*parameters)
        @text = parameters.join(' ')

        super('ACTION', *parameters)
      end
    end
  end
end
