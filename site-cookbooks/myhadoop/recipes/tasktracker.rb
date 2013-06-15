service "hadoop-0.20-mapreduce-tasktracker" do
    action :nothing
end

package "hadoop-0.20-mapreduce-tasktracker" do
    action :install
    notifies :start, "service[hadoop-0.20-mapreduce-tasktracker]"
end
