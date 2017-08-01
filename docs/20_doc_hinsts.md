## doc hints

create a new Toc:

´´´sh
grep "^##" *.md| sed "s/^\(.*md\):\(#*\)\s\(.*\)$/\2ö [\3](docs\/\1)/; s/#/  /g;s/ö/-/;s/^    //" >> 01_Introduction.md
´´´

