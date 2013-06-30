template "/etc/init.d/storm-supervisor" do
    source "storm_initd_script.erb"
    mode 00755
end

service "storm-supervisor" do
    supports :status => true, :restart => true
    action :start
end
