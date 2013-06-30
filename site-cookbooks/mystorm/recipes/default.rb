#
# Cookbook Name:: mystorm
# Recipe:: default
#
# Copyright 2013, Eugene Suchkov
#
# All rights reserved - Do Not Redistribute
#

%w(libtool autoconf automake build-essential uuid-dev git pkg-config unzip).each do |p|
    package p do
        action :install
    end
end

remote_file "/tmp/zeromq-#{node[:storm][:zeromq][:version]}.tar.gz" do
    source "http://download.zeromq.org/zeromq-#{node[:storm][:zeromq][:version]}.tar.gz"
end

bash "install ZeroMQ" do
    cwd "/tmp"
    code <<-EOC
    tar zxf zeromq-#{node[:storm][:zeromq][:version]}.tar.gz
    cd zeromq-#{node[:storm][:zeromq][:version]}
    ./configure
    make
    make install
    EOC
    creates "/usr/local/lib/libzmq.so"
end

remote_file "/tmp/storm-#{node[:storm][:version]}.zip" do
    source "https://github.com/downloads/nathanmarz/storm/storm-#{node[:storm][:version]}.zip"
end

bash "install JZMQ" do
    cwd "/tmp"
    code <<-EOC
git clone --depth 1 https://github.com/nathanmarz/jzmq.git
cd jzmq
./autogen.sh
./configure
touch src/classdist_noinst.stamp
cd src/
CLASSPATH=.:./.:$CLASSPATH javac -d . org/zeromq/ZMQ.java org/zeromq/App.java org/zeromq/ZMQForwarder.java org/zeromq/EmbeddedLibraryTools.java org/zeromq/ZMQQueue.java org/zeromq/ZMQStreamer.java org/zeromq/ZMQException.java
cd ..
make
sudo make install
    EOC
    creates "/usr/local/share/java/zmq.jar"
end

bash "install Storm" do
    cwd "/tmp"
    code <<-EOC
    unzip storm-#{node[:storm][:version]}.zip
    mv storm-#{node[:storm][:version]} /opt/storm
    EOC
    creates "/opt/storm/bin/storm"
end

zookeepers = search(:node,"chef_environment:#{node.chef_environment} AND role:zookeeper")
nimbus = search(:node,"chef_environment:#{node.chef_environment} AND role:nimbus").first

directory node["storm"]["local_dir"] do
    recursive true
    action :create
end

template "/opt/storm/conf/storm.yaml" do
    source "storm.yaml.erb"
    variables :local_dir => node["storm"]["local_dir"],
              :zookeepers => zookeepers,
              :nimbus => nimbus

end

directory "/var/log/storm/" do
    action :create
    recursive true
end
