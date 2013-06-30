template "/etc/init.d/storm-nimbus" do
    source "storm_initd_script.erb"
    mode 00755
end

service "storm-nimbus" do
    supports :status => true, :restart => true
    action :start
end
