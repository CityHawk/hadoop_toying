service "hadoop-hdfs-datanode" do
    action :nothing
end

package "hadoop-hdfs-datanode" do
    action :install
end

directory "/data/1/dfs/dn" do
    action :create
    recursive true
    group "hadoop"
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
    :zookeepers => zookeepers
    notifies :start, "service[hadoop-hdfs-datanode]", :immediately
end
