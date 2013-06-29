#
# Cookbook Name:: myzookeeper
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

service "zookeeper-server" do
    supports :status => true, :restart => true, :init => true
    action :nothing
end

package "zookeeper-server" do
    action :install
end

template "/var/lib/zookeeper/myid" do
    source "myid.erb"
    owner "zookeeper"
    group "zookeeper"
end

zoonodes=search(:node,"chef_environment:#{node.chef_environment} AND role:zookeeper")
template "/etc/zookeeper/conf/zoo.cfg" do
    source "zoo.cfg.erb"
    variables :zoonodes => zoonodes
end

bash "zookeeper-server-init" do
    code "service zookeeper-server init"
    creates "/var/lib/zookeeper/version-2"
    notifies :restart, "service[zookeeper-server]", :delayed
end
