## doc hints

create a new Toc:

:8,28s/^\(.*md\):\(#*\)\s\(.*\)$/\2 [docs\/\1] [\3]/g
:8,28s/#/*/g
