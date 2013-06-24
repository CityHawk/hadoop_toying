directory "/data/1/dfs/jn" do
    action :create
    recursive true
    owner "hdfs"
    group "hdfs"
end

service "hadoop-hdfs-journalnode" do
    action :nothing
end

package "hadoop-hdfs-journalnode" do
    action :install
        notifies :start, "service[hadoop-hdfs-journalnode]", :immediately
end
