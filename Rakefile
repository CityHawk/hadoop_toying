#!/usr/bin/env ruby
require 'digital_ocean'
require 'yaml'
require 'colorize'
require 'net/ssh'
require 'chef/knife'

@config_data = YAML.load_file("#{ENV['HOME']}/.tugboat")
DATANODES=3

@dc = DigitalOcean::API.new :client_id => @config_data['authentication']['client_key'], :api_key => @config_data['authentication']['api_key'] #, :debug => true

def status o
    if o.status == "OK"
        o.status.colorize (:green)
    else
        o.status.colorize (:red)
    end
end

task :create do
    def create_node name, size, image
        dropletname = name
        puts "Creating node #{dropletname}".colorize (:blue)
        drop = @dc.droplets.create :name => dropletname,\
        :size_id => size, :image_id => image, :region_id => 1, :ssh_key_ids => @config_data['other']['ssh_key_id']
        #puts drop
        puts "Node created #{dropletname} #{status(drop)}"
        # wait until DNS changes propagate
        puts "Waiting for ip_address of node #{dropletname}"
        while 1
            poll_drop = @dc.droplets.show(drop.droplet.id)
            break if poll_drop.droplet.ip_address
            sleep 5
        end
        return poll_drop
        #printf "\nnode #{dropletname} got ip address #{poll_drop.droplet.ip_address}. Creating record..."
        #rec = @dc.domains.create :name => dropletname, :ip_address => poll_drop.droplet.ip_address
        #puts status(rec)

    end

    def server_ready? node
        begin
            Timeout::timeout(1) do
                begin
                    s = TCPSocket.new(node.droplet.ip_address, 22)
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

    blueprint = YAML.load_file("blueprint.yml")
    @env_id = (Time.now.to_i).to_s(36)
    # create chef environment
    puts `knife environment create e_#{@env_id} -d`
    threads = []
    blueprint["nodes"].each do |name, node|
        threads << Thread.new do
            nodename = "#{name}-#{@env_id}.#{@config_data['other']['domain']}"
            # create N servers
            fnode = create_node nodename, node["size"], node["image"]
            puts "waiting node #{nodename} to be accessible"
            while !server_ready? fnode do
                sleep 10
            end
            #knife bootstap servers
            puts "bootstrapping node #{nodename}"
            `knife bootstrap #{fnode.droplet.ip_address} -x root --no-host-key-verify`
            puts "bootstrap node #{nodename} finished, exit code #{$?}"
        end
    end

    threads.each do |t|
        t.join
    end

    # add servers to environment
    # add roles to the servers
    # run chef-client on them
end

task :clear, [:e_id] do |t, args|
    # find all the nodes within same e_id
    puts "Searching for droplets of name #{args.e_id}".colorize (:green)
    droplets_to_kill = @dc.droplets.list.droplets.select do |d|
        d[:name].include? args.e_id
    end
    puts "Searching for domains of name #{args.e_id}".colorize (:green)
    domains_to_kill = @dc.domains.list.domains.select do |d|
        d[:name].include? args.e_id
    end

    droplets_to_kill.each do |d|
        printf "Destroying droplet #{d.id} #{d.name} "
        puts status(@dc.droplets.delete d.id)
    end

    domains_to_kill.each do |d|
        printf "Destroying domain #{d.id} #{d.name} #{d.ip_address} "
        puts status(@dc.domains.delete d.id)
    end

    puts `knife environment delete e_#{args.e_id} -y`
    puts `knife node bulk delete #{args.e_id} -y`
    puts `knife client bulk delete #{args.e_id} -y`


end
