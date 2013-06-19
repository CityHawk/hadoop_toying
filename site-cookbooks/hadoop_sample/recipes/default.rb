#
# Cookbook Name:: hadoop_sample
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# The example is taken from http://www.analyticalway.com/?p=124


bash "hput data" do
    user "hdfs"
    code <<-EOB
    hadoop fs -mkdir -p /user/mydir
    hadoop fs -put /tmp/pg76.txt /user/mydir/
    EOB
    action :nothing
end

remote_file "/tmp/pg76.txt" do
    source "http://www.gutenberg.org/cache/epub/76/pg76.txt"
    owner "hdfs"
    notifies :run, "bash[hput data]"
end

# you can launch all that stuff with
# hadoop jar /usr/lib/hadoop-0.20-mapreduce/hadoop-examples.jar wordcount /user/mydir/pg76.txt HF.out
