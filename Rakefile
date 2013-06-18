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

def lognode node, msg
    puts "#{node}: ".colorize(:yellow)+msg
end

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

def create_node dropletname, size, image
    drop = @dc.droplets.create :name => dropletname,\
    :size_id => size, :image_id => image, :region_id => 1, :ssh_key_ids => @config_data['other']['ssh_key_id']
    #puts drop
    lognode dropletname, "node created #{status(drop)}"
    # wait until DNS changes propagate
    lognode dropletname, "waiting for ip_address of node"
    while 1
        poll_drop = @dc.droplets.show(drop.droplet.id)
        break if poll_drop.droplet.ip_address
        sleep 5
    end
    rec = @dc.domains.create :name => dropletname, :ip_address => poll_drop.droplet.ip_address
    lognode dropletname, " got ip address #{poll_drop.droplet.ip_address}. Creating record... #{status(rec)}"
    sleep 300
    while !dns_ready? dropletname do
        sleep 30
    end
    lognode dropletname, "waiting node to be accessible"
    while !server_ready? dropletname do
        sleep 10
    end
    return dropletname
    #puts status(rec)

end

task :create do
    blueprint = YAML.load_file("blueprint.yml")
    @env_id = (Time.now.to_i).to_s(36)
    # create chef environment
    puts `knife environment create e_#{@env_id} -d`
    threads = []
    node_ids=[]
    blueprint["nodes"].each do |name, node|
        threads << Thread.new do
            nodename = "#{name}-#{@env_id}.#{@config_data['other']['domain']}"
            # spin up server
            lognode nodename, "creating node"
            fnode = create_node nodename, node["size"], node["image"]
            node_ids.push(fnode)
            #knife bootstap servers
            lognode nodename, "bootstrapping node"
            `knife bootstrap #{fnode} -x root --no-host-key-verify`
            lognode nodename, "bootstrap node finished, exit code #{$?.to_i}"
            # add servers to environment
            # add roles to the servers
            lognode nodename, "setting  environment and run_list to #{node["role"]}"
            `knife exec -E "n=Chef::Node.load('#{nodename}'); n.chef_environment='e_#{@env_id}'; n.run_list('role[#{node["role"]}]'); n.save"`
            lognode nodename, "node is ready"
        end
        sleep 1
    end

    threads.each do |t|
        t.join
    end

    # run chef-client on them
    puts "JFYI: #{node_ids.join(" ")}"

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
