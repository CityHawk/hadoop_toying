name "supervisor"
description "supervisor"
run_list "recipe[java]",
         "recipe[mystorm]",
         "recipe[mystorm::supervisor]"

