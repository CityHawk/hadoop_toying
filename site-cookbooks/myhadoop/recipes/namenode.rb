service "hadoop-hdfs-namenode" do
    action :nothing
end

package "hadoop-hdfs-namenode" do
    action :install
end

directory "/data/1/dfs/nn" do
    action :create
    group "hadoop"
    recursive true
end

namenodes = search(:node,"chef_environment:#{node.chef_environment} AND role:namenode")
if namenodes.length == 2
    journalnodes = search(:node,"chef_environment:#{node.chef_environment} AND role:journalnode")
    zookeepers = search(:node,"chef_environment:#{node.chef_environment} AND role:zookeeper")
    template "/etc/hadoop/conf/core-site.xml" do
        source "core-site.xml.erb"
        group "hadoop"
        variables :namenode => namenodes,
                   :ha => true,
                   :journalnodes => journalnodes,
                   :zookeepers => zookeepers
    end
    if zookeepers && zookeepers.length > 0
        # fencing keys
        directory "/var/lib/hadoop-hdfs/.ssh" do
            owner "hdfs"
            group "hdfs"
            mode 00700
        end

        cookbook_file "/var/lib/hadoop-hdfs/.ssh/id_rsa" do
            source "sshfence"
            owner "hdfs"
            group "hdfs"
            mode 00600
        end

        cookbook_file "/var/lib/hadoop-hdfs/.ssh/authorized_keys" do
            source "sshfence.pub"
            owner "hdfs"
            group "hdfs"
            mode 00600
        end

        service "hadoop-hdfs-zkfc" do
            action :nothing
        end

        package "hadoop-hdfs-zkfc" do
            action :install
        end

        template "/etc/hadoop/conf/hdfs-site.xml" do
            source "hdfs-site.xml.erb"
            group "hadoop"
            variables :ha => true,
            :zookeepers => zookeepers
        end

        if node["hadoop"]["namenode"]["primary"]
            bash "format ZK" do
                user "hdfs"
                code "hdfs zkfc -formatZK && touch /var/tmp/zkformatted"
                creates "/var/tmp/zkformatted"
                notifies :restart, "service[hadoop-hdfs-zkfc]", :immediately
            end
        end
    else
        template "/etc/hadoop/conf/hdfs-site.xml" do
            source "hdfs-site.xml.erb"
            group "hadoop"
            variables :ha => true,
            :zookeepers => zookeepers
        end
    end
    if node["hadoop"]["namenode"]["primary"]
        bash "format hdfs node" do
            user "hdfs"
            code "hdfs namenode -format"
            creates "/var/lib/hadoop-hdfs/cache/hdfs/dfs/name/current/VERSION"
            notifies :start, "service[hadoop-hdfs-namenode]", :immediately
        end
    else
        if zookeepers && zookeepers.length > 2
            primarynn = search(:node,"chef_environment:#{node.chef_environment} AND hadoop_namenode_primary:true").first
            bash "rsync standby" do
                user "hdfs"
                code "rsync -avz -e ssh hdfs@#{primarynn["fqdn"]}:/var/lib/hadoop-hdfs/cache/* /var/lib/hadoop-hdfs/cache/"
                creates "/var/lib/hadoop-hdfs/cache/hdfs/dfs/name/current/VERSION"
                notifies :start, "service[hadoop-hdfs-namenode]", :immediately
            end
        else
            bash "bootstrap standby" do
                user "hdfs"
                code "hdfs namenode -bootstrapStandby"
                creates "/var/lib/hadoop-hdfs/cache/hdfs/dfs/name/current/VERSION"
                notifies :start, "service[hadoop-hdfs-namenode]", :immediately
            end
        end
    end
else
    # in case of 3 or more nns it will fallback to the 1
    template "/etc/hadoop/conf/core-site.xml" do
        source "core-site.xml.erb"
        group "hadoop"
        variables :namenode => namenodes.first,
                   :ha => false
    end

    bash "format hdfs node" do
        user "hdfs"
        code "hdfs namenode -format"
        creates "/var/lib/hadoop-hdfs/cache/hdfs/dfs/name/current/VERSION"
        notifies :start, "service[hadoop-hdfs-namenode]", :immediately
    end
end

