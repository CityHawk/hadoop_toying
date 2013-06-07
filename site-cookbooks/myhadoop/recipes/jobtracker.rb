service "hadoop-0.20-mapreduce-jobtracker" do
    action :nothing
end

package "hadoop-0.20-mapreduce-jobtracker" do
    action :install
    notifies :start, "service[hadoop-0.20-mapreduce-jobtracker]"
end
