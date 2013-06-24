name "jobtracker"
description "jobtracker"
run_list "recipe[java]",
         "recipe[myhadoop]",
         "recipe[myhadoop::jobtracker]"

