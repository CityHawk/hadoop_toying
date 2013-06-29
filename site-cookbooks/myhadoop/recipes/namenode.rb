service "hadoop-hdfs-namenode" do
    action :nothing
end

package "hadoop-hdfs-namenode" do
    action :install
end

directory "/data/1/dfs/nn" do
    action :create
    group "hadoop"
    recursive true
end

# configure our setup
namenodes = search(:node,"chef_environment:#{node.chef_environment} AND role:namenode")
if namenodes.length == 2
    ha = true
    primarynn = search(:node,"chef_environment:#{node.chef_environment} AND hadoop_namenode_primary:true").first
else
    ha = false
end

if node["hadoop"]["namenode"]["primary"]
    primary = true
else
    primary = false
end

journalnodes = search(:node,"chef_environment:#{node.chef_environment} AND role:journalnode")
if journalnodes && journalnodes.length > 0
    qjm = true
else
    qjm = false
end

zookeepers = search(:node,"chef_environment:#{node.chef_environment} AND role:zookeeper")
if zookeepers && zookeepers.length > 0
    autofailover = true
else
    autofailover = false
end

# fencing and rsync keys
directory "/var/lib/hadoop-hdfs/.ssh" do
    only_if { ha }
    owner "hdfs"
    group "hdfs"
    mode 00700
end

cookbook_file "/var/lib/hadoop-hdfs/.ssh/id_rsa" do
    only_if { ha }
    source "sshfence"
    owner "hdfs"
    group "hdfs"
    mode 00600
end

cookbook_file "/var/lib/hadoop-hdfs/.ssh/authorized_keys" do
    only_if { ha }
    source "sshfence.pub"
    owner "hdfs"
    group "hdfs"
    mode 00600
end


template "/etc/hadoop/conf/core-site.xml" do
    source "core-site.xml.erb"
    group "hadoop"
    variables :namenode => namenodes,
    :ha => ha,
    :qjm => qjm,
    :autofailover => autofailover,
    :journalnodes => journalnodes,
    :zookeepers => zookeepers
end

template "/etc/hadoop/conf/hdfs-site.xml" do
    source "hdfs-site.xml.erb"
    group "hadoop"
    variables :ha => ha,
    :autofailover => autofailover,
    :zookeepers => zookeepers
end


service "hadoop-hdfs-zkfc" do
    action :nothing
    only_if { ha && autofailover }
end

package "hadoop-hdfs-zkfc" do
    action :install
    only_if { ha && autofailover }
end

bash "format ZK" do
    user "hdfs"
    code "hdfs zkfc -formatZK && touch /var/tmp/zkformatted"
    only_if { !File.exists?("/var/tmp/zkformatted") && ha && primary && autofailover }
    notifies :restart, "service[hadoop-hdfs-zkfc]", :delayed
end

bash "format hdfs node" do
    user "hdfs"
    code "hdfs namenode -format"
    only_if { !File.exist?("/var/lib/hadoop-hdfs/cache/hdfs/dfs/name/current/VERSION") && ( primary || !ha ) }
    notifies :start, "service[hadoop-hdfs-namenode]", :immediately
end

bash "rsync standby" do
    user "hdfs"
    code "rsync -avz -e 'ssh -o StrictHostKeyChecking=no' hdfs@#{primarynn["fqdn"]}:/var/lib/hadoop-hdfs/cache/* /var/lib/hadoop-hdfs/cache/"
    only_if { !File.exist?("/var/lib/hadoop-hdfs/cache/hdfs/dfs/name/current/VERSION") && ha && !primary }
    notifies :start, "service[hadoop-hdfs-namenode]", :immediately
end

