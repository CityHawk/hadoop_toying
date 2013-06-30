name "nimbus"
description "nimbus"
run_list "recipe[java]",
         "recipe[mystorm]",
         "recipe[mystorm::nimbus]"

