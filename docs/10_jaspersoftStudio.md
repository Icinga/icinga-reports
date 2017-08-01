## Jaspersoft Studio

Originally the reports were produced with iReport, but it's recommended not to use this tool anymore.

Jasper Studio is based on Eclipse. Download a bundled installer or use eclipse Market for installation.


### Install icinga libraries

When you try to edit the existing Reports with jasper Studio make sure you've added the DateHelper.

 1. Create a new jasper project
 1. Open the properties for this project
 1. goto "Java Build Path" -> "Libraries", klick on "Add External JAR"
    1. choose the icinga-reporting.jar located in icinga-reports/java/icinga-reports.jar
