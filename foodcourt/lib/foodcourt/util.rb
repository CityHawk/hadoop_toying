require 'socket'

module FoodUtil
    def server_ready? node
        begin
            Timeout::timeout(1) do
                begin
                    s = TCPSocket.new(node, 22)
                    s.close
                    return true
                rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
                    return false
                end
            end
        rescue Timeout::Error
        end

        return false
    end

    def dns_ready? hostname
        begin
            Socket.gethostbyname hostname
            true
        rescue
            false
        end
    end

end
