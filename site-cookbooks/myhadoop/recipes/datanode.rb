service "hadoop-hdfs-datanode" do
    action :nothing
end

package "hadoop-hdfs-datanode" do
    action :install
    notifies :start, "service[hadoop-hdfs-datanode]", :immediately
end
