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
    template "/etc/hadoop/conf/core-site.xml" do
        source "core-site.xml.erb"
        group "hadoop"
        variables :namenode => namenodes,
                   :ha => true,
                   :journalnodes => journalnodes
        notifies :start, "service[hadoop-hdfs-datanode]", :immediately
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

