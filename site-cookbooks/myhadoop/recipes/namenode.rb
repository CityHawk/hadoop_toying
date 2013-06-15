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

namenode = search(:node,"chef_environment:#{node.chef_environment} AND role:namenode").first

template "/etc/hadoop/conf/core-site.xml" do
    source "core-site.xml.erb"
    group "hadoop"
    variables :namenode => namenode
end

bash "format hdfs node" do
    user "hdfs"
    code "hdfs namenode -format"
    creates "/var/lib/hadoop-hdfs/cache/hdfs/dfs/name/current/VERSION"
    notifies :start, "service[hadoop-hdfs-namenode]", :immediately
end
