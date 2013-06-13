#!/usr/bin/env ruby
require 'digital_ocean'
require 'yaml'
require 'colorize'
require 'net/ssh'


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
    def create_node name
        dropletname = name
        puts "Creating node #{dropletname}".colorize (:blue)
        drop = @dc.droplets.create :name => dropletname,\
        :size_id => 66, :image_id => 2676, :region_id => 1, :ssh_key_ids => @config_data['other']['ssh_key_id']
        puts "Node created #{drop.droplet.id} #{status(drop)}"
        # wait until DNS changes propagate
        printf "Waiting for ip_address"
        while 1
            poll_drop = @dc.droplets.show(drop.droplet.id)
            break if poll_drop.droplet.ip_address
            printf '.'
            sleep 5
        end
        printf "\n"
        return poll_drop
        #printf "\nnode #{dropletname} got ip address #{poll_drop.droplet.ip_address}. Creating record..."
        #rec = @dc.domains.create :name => dropletname, :ip_address => poll_drop.droplet.ip_address
        #puts status(rec)

    end
    @env_id = (Time.now.to_i).to_s(36)
    # create chef environment
    puts `knife environment create e_#{@env_id} -d`

    # create N servers
    nodes = []
    node_names = %w(nn-001 dn-001 dn-002 dn-003).map { |i| "#{i}-#{@env_id}.#{@config_data['other']['domain']}" }
    node_names.each do |n|
        nodes.push(create_node(n))
    end
    puts nodes
    # wait for servers to come up and running
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
    # def server_ready? hostname
    #     begin
    #         Socket.gethostbyname hostname
    #         true
    #     rescue
    #         false
    #     end
    # end

    printf "Waiting while servers are up\n".colorize (:blue)
    while 1
        a = nodes.select {|n| server_ready? n }
        break if nodes.size == a.size

        printf " #{nodes.size - a.size} more to go...\n".colorize(:yellow)
        sleep 10
    end

    #knife bootstap servers
    nodes.each do |node|
        puts `knife bootstrap #{node.droplet.ip_address} -x root --no-host-key-verify`
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
