name "datanode"
description "datanode"
run_list "recipe[java]",
         "recipe[myhadoop]",
         "recipe[myhadoop::datanode]"

