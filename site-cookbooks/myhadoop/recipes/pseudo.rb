#
# Cookbook Name:: hadoop_single_node
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

apt_repository "cloudera" do
      uri "http://archive.cloudera.com/cdh4/ubuntu/precise/amd64/cdh"
      arch "amd64"
      distribution "precise-cdh4"
      components ["contrib"]
      key "http://archive.cloudera.com/cdh4/ubuntu/precise/amd64/cdh/archive.key"
end

package "hadoop-0.20-conf-pseudo" do
    action :install
end

service "hadoop-hdfs-datanode" do
    action :nothing
end

service "hadoop-hdfs-namenode" do
    action :nothing
end

bash "format hdfs node" do
    user "hdfs"
    code "hdfs namenode -format"
    notifies :start, "service[hadoop-hdfs-datanode]", :immediately
    notifies :start, "service[hadoop-hdfs-namenode]", :immediately
end

service "hadoop-0.20-mapreduce-jobtracker" do
    action :nothing
end

service "hadoop-0.20-mapreduce-tasktracker" do
    action :nothing
end

bash "add /tmp directory" do
    user "hdfs"
    code <<-EOB
    hadoop fs -mkdir /tmp
    hadoop fs -chmod -R 1777 /tmp
    hadoop fs -mkdir -p /var/lib/hadoop-hdfs/cache/mapred/mapred/staging
    hadoop fs -chmod 1777 /var/lib/hadoop-hdfs/cache/mapred/mapred/staging
    hadoop fs -chown -R mapred /var/lib/hadoop-hdfs/cache/mapred
    hadoop fs -ls /
    EOB
    notifies :start, "service[hadoop-0.20-mapreduce-jobtracker]"
    notifies :start, "service[hadoop-0.20-mapreduce-tasktracker]"
end

