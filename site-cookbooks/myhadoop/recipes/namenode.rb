service "hadoop-hdfs-namenode" do
    action :nothing
end

package "hadoop-hdfs-namenode" do
    action :install
end

bash "format hdfs node" do
    user "hdfs"
    code "hdfs namenode -format"
    notifies :start, "service[hadoop-hdfs-namenode]", :immediately
end
