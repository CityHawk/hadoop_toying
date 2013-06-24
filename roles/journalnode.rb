name "journalnode"
description "journalnode"
run_list "recipe[java]",
         "recipe[myhadoop]",
         "recipe[myhadoop::journalnode]"
