require "foodcourt/node"
require 'digital_ocean'

class Worker

    attr_accessor :steps, :env_id

    def initialize blueprint_file
         @blueprint = YAML.load_file("blueprint.yml")
         @nodes = blueprint["nodes"]
         @dc = DigitalOcean::API.new :client_id => @config_data['authentication']['client_key'], :api_key => @config_data['authentication']['api_key'],
         
    end

    def go
        @nodes.each do |node, data|
            threads << Thread.new do
                n = Node.new :env_id => @env_id,
                    :id => node,
                    :domain => config[:domain],
                    :cloud => @dc,
                    :size => data["size"],
                    :image => data["size"],
                    :roles => data["roles"],
                    :ssh_keys => config["ssh_keys"]
                if @steps.include? create
                    ip = n.create
                end
                if @steps.include? set_dns
                    set_
                end
            end
        end

    end

end
