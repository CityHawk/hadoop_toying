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

namenode = search(:node,"chef_environment:#{node.chef_environment} AND role:namenode").first

template "/etc/hadoop/conf/core-site.xml" do
    source "core-site.xml.erb"
    group "hadoop"
    variables :namenode => namenode
    notifies :start, "service[hadoop-hdfs-datanode]", :immediately
end
