JAVA=java
JAVAC=javac
JAR=jar

all: build

clean:
	rm -f org/icinga/reporting/DateHelper.class
	rm -f icinga-reporting.jar

build: icinga-reporting.jar

org/icinga/reporting/DateHelper.class:
	$(JAVAC) org/icinga/reporting/DateHelper.java

icinga-reporting.jar: org/icinga/reporting/DateHelper.class
	$(JAR) cfm icinga-reporting.jar Manifest.txt org/icinga/reporting/DateHelper.class

test: build
	$(JAVA) -jar icinga-reporting.jar

# vi: ts=4 sw=4 noexpandtab :
