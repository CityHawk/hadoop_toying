service "hadoop-hdfs-secondarynamenode" do
    action :nothing
end

package "hadoop-hdfs-secondarynamenode" do
    action :install
    notifies :start, "service[hadoop-hdfs-secondarynamenode]", :immediately
end
