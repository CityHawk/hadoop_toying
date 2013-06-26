name "zookeeper"
description "zookeeper server"
run_list "recipe[java]",
         "recipe[myzookeeper]"
