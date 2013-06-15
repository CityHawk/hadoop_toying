name "namenode"
description "namenode and jobtracker"
run_list "recipe[java]",
         "recipe[myhadoop]",
         "recipe[myhadoop::namenode]",
         "recipe[myhadoop::jobtracker]"

