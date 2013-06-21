#!/usr/bin/env ruby
require 'digital_ocean'
require 'yaml'
require 'logger'
require 'mixlib/cli'

@config_data = YAML.load_file("#{ENV['HOME']}/.tugboat")
@log = Logger.new(STDOUT)
@log.datetime_format = "%Y-%m-%d %H:%M:%S "


@dc = DigitalOcean::API.new :client_id => @config_data['authentication']['client_key'], :api_key => @config_data['authentication']['api_key'] #, :debug => true

class CreateCLI
    include Mixlib::CLI

    option :blueprint,
        :short => "-b",
        :long => "--blueprint BLUEPRINT",
        :description => "Use blueprint",
        :default => 'blueprint.yaml'

    option :env_id,
        :short => "-e",
        :long => "--environment ENVIRONMENT",
        :description => "Name your environment"

    option :log_level,
        :short => "-l LEVEL",
        :long  => "--log_level LEVEL",
        :description => "Set the log level (debug => 0, info => 1, warn => 2, error => 3, fatal => 4)",
        :default => 1,
        :proc => Proc.new { |l| l.to_i }

    option :help,
        :short => "-h",
        :long => "--help",
        :description => "Show this message",
        :on => :tail,
        :boolean => true,
        :show_options => true,
        :exit => 0
end

class ClearCLI
    include Mixlib::CLI

    option :env_id,
        :short => "-e",
        :long => "--environment ENVIRONMENT",
        :description => "Name your environment",
        :required => true

    option :log_level,
        :short => "-l LEVEL",
        :long  => "--log_level LEVEL",
        :description => "Set the log level (debug => 0, info => 1, warn => 2, error => 3, fatal => 4)",
        :default => 1,
        :proc => Proc.new { |l| l.to_i }

    option :help,
        :short => "-h",
        :long => "--help",
        :description => "Show this message",
        :on => :tail,
        :boolean => true,
        :show_options => true,
        :exit => 0
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
    #@log.info drop
    @log.info dropletname + " node created"
    # wait until DNS changes propagate
    @log.info dropletname + " waiting for ip_address of node"
    while 1
        poll_drop = @dc.droplets.show(drop.droplet.id)
        break if poll_drop.droplet.ip_address
        sleep 5
    end
    rec = @dc.domains.create :name => dropletname, :ip_address => poll_drop.droplet.ip_address
    if rec.status == 'OK'
        @log.info dropletname + " got ip address #{poll_drop.droplet.ip_address}. Created DNS record."
    else
        @log.error dropletname + " got ip address #{poll_drop.droplet.ip_address}. Failed to create DNS record."
    end
    sleep 300
    while !dns_ready? dropletname do
        sleep 30
    end
    @log.info dropletname + " waiting node to be accessible"
    while !server_ready? dropletname do
        sleep 10
    end
    return dropletname
    #@log.info status(rec)

end

def create (params)
    blueprint = YAML.load_file("blueprint.yml")
    if params[:env_id]
        @log.debug "Enforcing environment #{params[:env_id]}"
        @env_id = params[:env_id]
    else
        @log.debug "You didn't tell me what env to use. Generating my very own"
        @env_id = (Time.now.to_i).to_s(36)
    end
    # create chef environment
    @log.info `knife environment create e_#{@env_id} -d`
    threads = []
    node_ids=[]
    blueprint["nodes"].each do |name, node|
        threads << Thread.new do
            nodename = "#{name}-#{@env_id}.#{@config_data['other']['domain']}"
            # spin up server
            @log.info nodename + " creating node"
            fnode = create_node nodename, node["size"], node["image"]
            node_ids.push(fnode)
            #knife bootstap servers
            @log.info nodename + " bootstrapping node"
            `knife bootstrap #{fnode} -x root --no-host-key-verify`
            @log.info nodename + "bootstrap node finished, exit code #{$?.to_i}"
            # add servers to environment
            # add roles to the servers
            @log.info nodename + " setting  environment and run_list to #{node["role"]}"
            `knife exec -E "n=Chef::Node.load('#{nodename}'); n.chef_environment='e_#{@env_id}'; n.run_list('role[#{node["role"]}]'); n.save"`
            @log.info nodename + " node is ready"
        end
        sleep 1
    end

    threads.each do |t|
        t.join
    end

    # run chef-client on them
    @log.info "JFYI: #{node_ids.join(" ")}"

end

def clear e_id
    # find all the nodes within same e_id
    @log.info "Searching for droplets of name #{e_id}"
    droplets_to_kill = @dc.droplets.list.droplets.select do |d|
        d[:name].include? e_id
    end
    @log.info "Searching for domains of name #{e_id}"
    domains_to_kill = @dc.domains.list.domains.select do |d|
        d[:name].include? e_id
    end

    droplets_to_kill.each do |d|
        s = @dc.droplets.delete d.id
        if s.status == 'OK'
            @log.info "Destroyed droplet #{d.id} #{d.name} "
        else
            @log.error "Failed to destroy droplet #{d.id} #{d.name} "
        end
    end

    domains_to_kill.each do |d|
        s = @dc.domains.delete d.id
        if s.status == 'OK'
            @log.info "Destroyed domain #{d.id} #{d.name} #{d.ip_address} "
        else
            @log.error "Failed to destroy domain #{d.id} #{d.name} #{d.ip_address} "
        end
    end

    @log.info `knife environment delete e_#{e_id} -y`
    @log.info `knife node bulk delete #{e_id} -y`
    @log.info `knife client bulk delete #{e_id} -y`
end


command = ARGV[0]
case command
when "create"
    cli = CreateCLI.new
    cli.parse_options
    @log.level = cli.config[:log_level]
    create :blueprint => cli.config[:blueprint], :env_id => cli.config[:env_id]
when "clear"
    cli = ClearCLI.new
    cli.parse_options
    @log.level = cli.config[:log_level]
    clear cli.config[:env_id]
else

end
