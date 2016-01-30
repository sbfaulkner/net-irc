module Net
  class IRC
    class CTCP
      attr_accessor :source, :target, :keyword, :parameters

      CTCP_REGEX = /\001(.*?)\001/

      def initialize(keyword, *parameters)
        @source = nil
        @keyword = keyword
        @parameters = parameters
      end

      def to_s
        str = "\001#{keyword}"
        str << parameters.collect { |p| " #{p}"}.join
        str << "\001"
      end

      class << self
        def parse(text)
          [
            text.gsub(CTCP_REGEX, ''),
            text.scan(CTCP_REGEX).flatten.collect do |message|
              parameters = message.split(' ')
              case keyword = parameters.shift
              when 'VERSION'
                CTCPVersion.new(*parameters)
              when 'PING'
                CTCPPing.new(*parameters)
              when 'CLIENTINFO'
                CTCPClientinfo.new(*parameters)
              when 'ACTION'
                CTCPAction.new(*parameters)
              when 'FINGER'
                CTCPFinger.new(*parameters)
              when 'TIME'
                CTCPTime.new(*parameters)
              when 'DCC'
                CTCPDcc.new(*parameters)
              when 'ERRMSG'
                CTCPErrmsg.new(*parameters)
              when 'PLAY'
                CTCPPlay.new(*parameters)
              else
                CTCP.new(keyword, *parameters)
              end
            end
          ]
        end
      end
    end
  end
end
