service "hadoop-0.20-mapreduce-jobtracker" do
    action :nothing
end

bash "add /tmp directory" do
    user "hdfs"
    code <<-EOB
    hadoop fs -mkdir -p /tmp
    hadoop fs -chmod -R 1777 /tmp
    hadoop fs -mkdir -p /var/lib/hadoop-hdfs/cache/mapred/mapred/staging
    hadoop fs -chmod 1777 /var/lib/hadoop-hdfs/cache/mapred/mapred/staging
    hadoop fs -chown -R mapred /var/lib/hadoop-hdfs/cache/mapred
    hadoop fs -ls /
    EOB
end

package "hadoop-0.20-mapreduce-jobtracker" do
    action :install
end

directory "/data/1/mapred/local" do
    action :create
    recursive true
    group "hadoop"
end

jobtracker = search(:node,"chef_environment:#{node.chef_environment} AND role:namenode").first

template "/etc/hadoop/conf/mapred-site.xml" do
    source "mapred-site.xml.erb"
    variables :jobtracker => jobtracker
    notifies :start, "service[hadoop-0.20-mapreduce-jobtracker]"
end
