name "tasktracker"
description "tasktracker"
run_list "recipe[java]",
         "recipe[myhadoop]",
         "recipe[myhadoop::tasktracker]"
