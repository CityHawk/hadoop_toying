%w(/data/1/dfs/nn /data/1/dfs/dn /data/1/dfs/snn).each do |d|
    directory d do
        action :create
        group "hadoop"
    end
end

