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

namenodes = search(:node,"chef_environment:#{node.chef_environment} AND role:namenode")
if namenodes.length == 2
    journalnodes = search(:node,"chef_environment:#{node.chef_environment} AND role:journalnode")
    zookeepers = search(:node,"chef_environment:#{node.chef_environment} AND role:zookeeper")
    template "/etc/hadoop/conf/core-site.xml" do
        source "core-site.xml.erb"
        group "hadoop"
        variables :namenode => namenodes,
                   :ha => true,
                   :journalnodes => journalnodes,
                   :zookeepers => zookeepers
        notifies :start, "service[hadoop-hdfs-datanode]", :immediately
    end
    if zookeepers.length > 0
        template "/etc/hadoop/conf/hdfs-site.xml" do
            source "hdfs-site.xml.erb"
            group "hadoop"
            variables :ha => true,
            :zookeepers => zookeepers
        end
    end
else
    # in case of 3 or more nns it will fallback to the 1
    template "/etc/hadoop/conf/core-site.xml" do
        source "core-site.xml.erb"
        group "hadoop"
        variables :namenode => namenodes.first,
                   :ha => false
        notifies :start, "service[hadoop-hdfs-datanode]", :immediately
    end
end

