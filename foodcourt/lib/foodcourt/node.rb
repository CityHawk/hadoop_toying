require 'logger'
require 'digital_ocean'
require 'foodcourt/util'

class Node

    def initialize(env_id, params)
        @log = Logger.new(STDOUT)
        @env_id = env_id
        @id = params[:id]
        @domain = params[:domain]
        @short_name = "#{@id}-#{@env_id}"
        @full_name = "#{@short_name}.#{@domain}"
        @cloud = params[:cloud]
        @size = params[:size]
        @image = params[:image]
        @ssh_keys = params[:ssh_keys]
        @roles = params[:roles]
    end

    def create
        drop = @cloud.droplets.create :name => @full_name,\
            :size_id => @size, :image_id => @image, :region_id => 1, :ssh_key_ids => @ssh_keys
        if drop.status == 'OK'
        @log.info @full_name + " node created #{drop}"
        else
            log.error @full_name + " Failed to create node"
            return nil
        end
        @log.info @full_name + "waiting for ip_address of node"
        while 1
            poll_drop = @cloud.droplets.show(drop.droplet.id)
            break if poll_drop.droplet.ip_address
            sleep 5
        end
        poll_drop.ip_address
    end

    def set_dns ip_address
        rec = @cloud.domains.create :name => @full_name, :ip_address => ip_address
        if rec.status == 'OK'
            log.info @full_name + " got ip address #{ip_address}. Created record. "
        else
            log.error "Failed to create record for node"
            false
        end
        sleep 300
        while !FoodUtil.dns_ready? @full_name do
            log.debug @full_name + " is not ready, waiting 30 more seconds"
            sleep 30
        end
        true
    end

    def validate node_id=@full_name
        while !FoodUtil.server_ready? node_id do
            sleep 10
        end
    end

    def bootstrap node=@full_name
        out = `knife bootstrap #{node} -x root --no-host-key-verify`
        log.debug @full_name + " bootstrap output\n"+out
        if $?.to_i == 0
            log.info @full_name + " bootstrap node finished"
            true
        else
            log.error @full_name + " bootstrap failed"
            false
        end
    end

    def configure chef_node = @full_name
            log.info @full_name + " setting  environment and run_list"
            run_list = @roles.map { |r| "'role[#{r}]'" }.join(',')
            log.debug @full_name + " roles are"
            `knife exec -E "n=Chef::Node.load('#{chef_node}'); n.chef_environment='#{@env_id}'; n.run_list(#{run_list}); n.save"`
    end

    def converge
        log.info "converge is not implemented, ssh to the node and run chef-client manually"

    end

    def get_node_ip
        all_droplets = dc.droplets.list
        
    end
end
