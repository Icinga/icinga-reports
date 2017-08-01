## doc hints

create a new Toc:

´´´sh
grep "^##" *.md| sed "s/^\(.*md\):\(#*\)\s\(.*\)$/\2ö [docs\/\1] [\3]/; s/#/  /g;s/ö/-/;s/^    //" >> 01_Introduction.md
´´´

