name "hadoop_single_node_test"
description "Just hadoop node"
run_list [
          "recipe[java]",
          "recipe[hadoop_single_node]",
          "recipe[hadoop_sample]"
] 
