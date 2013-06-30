name "ui"
description "ui"
run_list "recipe[java]",
         "recipe[mystorm]",
         "recipe[mystorm::ui]"
