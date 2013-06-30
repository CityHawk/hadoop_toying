template "/etc/init.d/storm-ui" do
    source "storm_initd_script.erb"
    mode 00755
end

service "storm-ui" do
    supports :status => true, :restart => true
    action :start
end
