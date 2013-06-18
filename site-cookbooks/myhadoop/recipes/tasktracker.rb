service "hadoop-0.20-mapreduce-tasktracker" do
    action :nothing
end

package "hadoop-0.20-mapreduce-tasktracker" do
    action :install
end

directory "/data/1/mapred/local" do
    action :create
    recursive true
    owner "mapred"
    group "hadoop"
    mode 00775
end

jobtracker = search(:node,"chef_environment:#{node.chef_environment} AND role:namenode").first

template "/etc/hadoop/conf/mapred-site.xml" do
    source "mapred-site.xml.erb"
    variables :jobtracker => jobtracker
    group "hadoop"
    mode 00644
    notifies :start, "service[hadoop-0.20-mapreduce-tasktracker]"
end
