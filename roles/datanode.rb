name "datanode"
description "datanode and tasktracker"
run_list "recipe[java]",
         "recipe[myhadoop]",
         "recipe[myhadoop::datanode]",
         "recipe[myhadoop::tasktracker]"

