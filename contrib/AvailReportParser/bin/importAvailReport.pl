#!/usr/bin/perl
=pod

=head1 NAME

 importAvailReport.pl - Import availibilty report from Icinga/Nagios to Mysql database
 
=head1 Version

Version 0.2.0

=head1 SYNOPSIS

 importAvailReport.pl -H <hostname> -S <service> -D <description> -T <timperiod> -R <rpttimeperiod> -c <config file>
 importAvailReport.pl [-H|-S|-D|-T|-R|-c]

=head1 OPTIONS

=over 4

=item -H <hostname> (required)

 Hostname from configured host in Icinga/Nagios
 
=item -S <service> (optional)

 Service description from configured service in Icinga/Nagios
 
=item -D <description> (optional: default 'New Report')

 Description for the report
 
=item -T <timeperiod> (optional: default 'lastmonth')

 The report period for the availibility report
 
=item -R <rpttimeperiod> (optional: default none)

 The configured timeperiod in Icinga/Nagios, which to be used to create a availibility report
 
=over

B<List of defined timeperiods:>

 * today	=> Today
 * last24hours	=> Last 24 hours
 * yesterday	=> Yesterday
 * thisweek	=> This week
 * last7days	=> Last 7 days
 * lastweek	=> Last week
 * thismonth	=> This month
 * last31days	=> Last 31 days
 * lastmonth	=> Last month (default)
 * thisyear	=> This year
 * lastyear	=> Last year
 * custum	=> Custom period report
 
=back
 
=item -c <config file> (optional: default 'default.ini')

 The configure file, which contains information about basic authentification to Icinga/Nagios, debugging etc.
 This script search config files in the folder ./etc. 

=back

=head1 AUTHOR

Michael Luebben <michael_luebben@web.de>

=head1 KNOWN ISSUES

may be

=head1 BUGS

may be

=head1 REQUIRES

Perl 5, strict, LWP, Getopt::Long, FindBin, Reporting::Availability, Config::Configuration, Debug::Debugger, 

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License (and no
later version).

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA

=head1 HISTORY

=cut
use strict;
use LWP 5.64;
use Getopt::Long;
use FindBin;
use lib "$FindBin::Bin/../include/modules";
use Parser::Availability;
use Database::DBHandler;
use Config::Configuration;
use Debug::Debugger;
use Data::Dumper;

my $optHostname;
my $optServicesDesc;
my $optReportDesc;
my $optTimeperiod;
my $optRptTimeperiod;
my $optConfigFile;
my $result;
my $reportTime = time();
my $reportID;
my $setUrlResult;
my $statusCode = "0";
my $message = "Begin parsing";


# +------------------------------------------------------+
# |                     Starting.....                    |
# +------------------------------------------------------+
# Get arguments
Getopt::Long::Configure('bundling');
GetOptions(
	"H=s" =>	\$optHostname, 		"hostname=s"		=> \$optHostname,		# required
	"S=s" =>	\$optServicesDesc, 	"services=s"		=> \$optServicesDesc, 	# optional
	"D=s" =>	\$optReportDesc, 	"description=s"		=> \$optReportDesc, 	# optional (default: New Report)
	"T=s" =>	\$optTimeperiod, 	"timeperiod=s"		=> \$optTimeperiod, 	# optional (default: lastmonth)
	"R=s" =>	\$optRptTimeperiod,	"rpttimeperiod=s"	=> \$optRptTimeperiod, 	# optional (default: none)
	"c=s" =>	\$optConfigFile, 	"configfile=s"		=> \$optConfigFile, 	# optional (default: default.ini)
);
	
# Check arguments
if (!$optHostname) {
	print "No hostname defined!\n";
	exit 3;
}

# Set not defined arguments to default parameters
if (!$optReportDesc) {
	$optReportDesc = "New Report"
}

if (!$optTimeperiod) {
	$optTimeperiod = "lastmonth"
}

if (!$optConfigFile) {
	$optConfigFile = "default.ini"
}

my $ReportAvail = new Availability();


# Read configuration file
my $Config = new Configuration($optConfigFile);


# Init debugger
my $Debug = new Debugger($Config->getParameter('DEBUGFILE'), $Config->getParameter('DEBUG'), $Config->getParameter('LOGLEVEL'));


# Set parameters for url
$ReportAvail->setUrlParameter('host',$optHostname);
$Debug->addMessage("LOGLEVEL 2: Parser::Availability->setUrlParameter('host', ".$optHostname.")", 2);

$ReportAvail->setUrlParameter('service',$optServicesDesc);
$Debug->addMessage("LOGLEVEL 2: Parser::Availability->setUrlParameter('service', ".$optServicesDesc.")", 2);

$setUrlResult = $ReportAvail->setUrlParameter('timeperiod',$optTimeperiod);
$Debug->addMessage("LOGLEVEL 2: Parser::Availability->setUrlParameter('timeperiod', ".$optTimeperiod.")", 2);
if ($setUrlResult == -1) {
	$Debug->addMessage("ERROR: ".$ReportAvail->getErrorMessage(), 1);
	$Debug->close();
	exit 3;
}

$setUrlResult = $ReportAvail->setUrlParameter('rpttimeperiod',$optRptTimeperiod);
$Debug->addMessage("LOGLEVEL 2: Parser::Availability->setUrlParameter('rpttimeperiod', ".$optRptTimeperiod.")", 2);


# Get url for availibility report
$ReportAvail->setUrlPath($Config->getParameter('URLPATH'));
$Debug->addMessage("LOGLEVEL 2: Parser::Availability->setUrlPath(".$Config->getParameter('URLPATH').")", 2);

$ReportAvail->setParserType($Config->getParameter('PARSERTYPE'));
$Debug->addMessage("LOGLEVEL 2: Parser::Availability->setParserType(".$Config->getParameter('PARSERTYPE').")", 2);

my $url = $ReportAvail->getUrl();
$Debug->addMessage("INFO: Create url: ".$url, 1);


# Get availalibility report from Icinga/Nagios
my $Browser = LWP::UserAgent->new;
$Debug->addMessage("LOGLEVEL 2: LWP::UserAgent->new", 2);

$Browser->credentials(
	$Config->getParameter('HOST').":".$Config->getParameter('PORT'),
	$Config->getParameter('REALM'),
	$Config->getParameter('USERNAME') => $Config->getParameter('PASSWORD')
);
$Debug->addMessage("LOGLEVEL 2: Browser->credentials(".$Config->getParameter('HOST').":".$Config->getParameter('PORT').", ".$Config->getParameter('REALM').", ".$Config->getParameter('USERNAME')." => xxxxxxx)", 2);

my $response = $Browser->get($url);
if ($response->is_success != 1) {
	$Debug->addMessage("ERROR: ".$response->status_line, 1);
	$Debug->close();
	exit 3;
} else {
	$Debug->addMessage("INFO: Response status ".$response->status_line, 1);
}

# Parse HTML content
my $parseResult = $ReportAvail->parseContent($response->content);
if ($parseResult == -1) {
	$Debug->addMessage("ERROR: ".$ReportAvail->getErrorMessage(), 1);
} else {
	$Debug->addMessage("INFO: ".$Config->getParameter('PARSERTYPE')." parsing successully!", 1);


	# +------------------------------------------------------+
	# |                Save data into database               |
	# +------------------------------------------------------+
	# Connect to database
	my $dbHost = $Config->getParameter('DBHOST');
	my $dbName = $Config->getParameter('DBNAME');
	my $dbUser = $Config->getParameter('DBUSER');
	my $dbPass = $Config->getParameter('DBPASS');
	
	my $DBHandler = new DBHandler($dbHost, $dbName, $dbUser, $dbPass, $Config->getParameter('TABLEPREFIX'));
	$Debug->addMessage("LOGLEVEL 2: new DBHandler(".$dbHost.", ".$dbName.", ".$dbUser.", xxxxxxxx)", 2);
	if ($DBHandler == -1) {
		$Debug->addMessage("ERROR: Can't connect to database!", 1);
	} else {
		$Debug->addMessage("INFO: Connect to database successful!", 1);
		
		# Init report
		$reportID = $DBHandler->createNewReport($optHostname, $optServicesDesc, $optReportDesc, $optTimeperiod, $optRptTimeperiod, $optConfigFile, "0", $statusCode ,$message);
		if ($reportID == -1) {
			$Debug->addMessage("ERROR: ".$DBHandler->getErrorMessage, 1);
			$Debug->close();
			exit 3;
		} else {
			my $stateDefinition;
			my $importState = 0;
			
			# +---------------------------------------------------------+
			# |                       Import OK/UP state                |
			# +---------------------------------------------------------+
			if ($ReportAvail->getReportType() eq "service") {
				$stateDefinition = "ok";
				if ($Config->getParameter('SERVICEOK') == 1) {
					$importState = 1;
					$Debug->addMessage("INFO: Importing service ok data...", 1);
				}
			} else {
				$stateDefinition = "up";
				if ($Config->getParameter('HOSTUP') == 1) {
					$importState = 1;
					$Debug->addMessage("INFO: Importing host up data...", 1);
				}
			}
			
			if ($importState == 1) {
				# ---===== Time =====---
				# Unscheduled
				my $greenUnscheduledTimeDays = $ReportAvail->getParsedBreakdownValue($stateDefinition,"unscheduled","time","days");
				my $greenUnscheduledTimeHours = $ReportAvail->getParsedBreakdownValue($stateDefinition,"unscheduled","time","hours");
				my $greenUnscheduledTimeMinutes = $ReportAvail->getParsedBreakdownValue($stateDefinition,"unscheduled","time","minutes");
				my $greenUnscheduledTimeSeconds = $ReportAvail->getParsedBreakdownValue($stateDefinition,"unscheduled","time","seconds");
				$DBHandler->insertAvailBreakdown($reportID, $stateDefinition, "unscheduled", "time", $greenUnscheduledTimeDays, $greenUnscheduledTimeHours, $greenUnscheduledTimeMinutes, $greenUnscheduledTimeSeconds);
	
				# Scheduled
				my $greenScheduledTimeDays = $ReportAvail->getParsedBreakdownValue($stateDefinition,"scheduled","time","days");
				my $greenScheduledTimeHours = $ReportAvail->getParsedBreakdownValue($stateDefinition,"scheduled","time","hours");
				my $greenScheduledTimeMinutes = $ReportAvail->getParsedBreakdownValue($stateDefinition,"scheduled","time","minutes");
				my $greenScheduledTimeSeconds = $ReportAvail->getParsedBreakdownValue($stateDefinition,"scheduled","time","seconds");
				$DBHandler->insertAvailBreakdown($reportID, $stateDefinition, "scheduled", "time", $greenScheduledTimeDays, $greenScheduledTimeHours, $greenScheduledTimeMinutes, $greenScheduledTimeSeconds);
				
				# Total
				my $greenTotalTimeDays = $ReportAvail->getParsedBreakdownValue($stateDefinition,"total","time","days");
				my $greenTotalTimeHours = $ReportAvail->getParsedBreakdownValue($stateDefinition,"total","time","hours");
				my $greenTotalTimeMinutes = $ReportAvail->getParsedBreakdownValue($stateDefinition,"total","time","minutes");
				my $greenTotalTimeSeconds = $ReportAvail->getParsedBreakdownValue($stateDefinition,"total","time","seconds");
				$DBHandler->insertAvailBreakdown($reportID, $stateDefinition, "total", "time", $greenTotalTimeDays, $greenTotalTimeHours, $greenTotalTimeMinutes, $greenTotalTimeSeconds);
				
				# ---===== Total Time =====---
				# Unscheduled
				my $greenUnscheduledTotaltime = $ReportAvail->getParsedBreakdownValue($stateDefinition,"unscheduled","totaltime");
				$DBHandler->insertAvailBreakdown($reportID, $stateDefinition, "unscheduled", "totaltime", $greenUnscheduledTotaltime);
				
				# Scheduled
				my $greenScheduledTotaltime = $ReportAvail->getParsedBreakdownValue($stateDefinition,"scheduled","totaltime");
				$DBHandler->insertAvailBreakdown($reportID, $stateDefinition, "scheduled", "totaltime", $greenScheduledTotaltime);
				
				# Total
				my $greenTotalTotaltime = $ReportAvail->getParsedBreakdownValue($stateDefinition,"total","totaltime");
				$DBHandler->insertAvailBreakdown($reportID, $stateDefinition, "total", "totaltime", $greenTotalTotaltime);
				
				# ---===== Known Time =====---
				# Unscheduled
				my $greenUnscheduledKnowntime = $ReportAvail->getParsedBreakdownValue($stateDefinition,"unscheduled","knowntime");
				$DBHandler->insertAvailBreakdown($reportID, $stateDefinition, "unscheduled", "knowntime", $greenUnscheduledKnowntime);
				
				# Scheduled
				my $greenScheduledKnowntime = $ReportAvail->getParsedBreakdownValue($stateDefinition,"scheduled","knowntime");
				$DBHandler->insertAvailBreakdown($reportID, $stateDefinition, "scheduled", "knowntime", $greenScheduledKnowntime);
				
				# Total
				my $greenTotalKnowntime = $ReportAvail->getParsedBreakdownValue($stateDefinition,"total","knowntime");
				$DBHandler->insertAvailBreakdown($reportID, $stateDefinition, "total", "knowntime", $greenTotalKnowntime);
			}
			
			# +------------------------------------------------------+
			# |                 Import WARNING state                 |
			# +------------------------------------------------------+
			$importState = 0;
			
			if ($ReportAvail->getReportType() eq "service") {
				if ($Config->getParameter('SERVICEWARNING') == 1) {
					$importState = 1;
					$Debug->addMessage("INFO: Importing service warning data...", 1);
				}
			}
			
			if ($importState == 1) {
				# ---===== Time =====---
				# Unscheduled
				my $orangeUnscheduledTimeDays = $ReportAvail->getParsedBreakdownValue("warning","unscheduled","time","days");
				my $orangeUnscheduledTimeHours = $ReportAvail->getParsedBreakdownValue("warning","unscheduled","time","hours");
				my $orangeUnscheduledTimeMinutes = $ReportAvail->getParsedBreakdownValue("warning","unscheduled","time","minutes");
				my $orangeUnscheduledTimeSeconds = $ReportAvail->getParsedBreakdownValue("warning","unscheduled","time","seconds");
				$DBHandler->insertAvailBreakdown($reportID, "warning", "unscheduled", "time", $orangeUnscheduledTimeDays, $orangeUnscheduledTimeHours, $orangeUnscheduledTimeMinutes, $orangeUnscheduledTimeSeconds);
				
				# Scheduled
				my $orangeScheduledTimeDays = $ReportAvail->getParsedBreakdownValue("warning","scheduled","time","days");
				my $orangeScheduledTimeHours = $ReportAvail->getParsedBreakdownValue("warning","scheduled","time","hours");
				my $orangeScheduledTimeMinutes = $ReportAvail->getParsedBreakdownValue("warning","scheduled","time","minutes");
				my $orangeScheduledTimeSeconds = $ReportAvail->getParsedBreakdownValue("warning","scheduled","time","seconds");
				$DBHandler->insertAvailBreakdown($reportID, "warning", "scheduled", "time", $orangeScheduledTimeDays, $orangeScheduledTimeHours, $orangeScheduledTimeMinutes, $orangeScheduledTimeSeconds);
				
				# Total
				my $orangeTotalTimeDays = $ReportAvail->getParsedBreakdownValue("warning","total","time","days");
				my $orangeTotalTimeHours = $ReportAvail->getParsedBreakdownValue("warning","total","time","hours");
				my $orangeTotalTimeMinutes = $ReportAvail->getParsedBreakdownValue("warning","total","time","minutes");
				my $orangeTotalTimeSeconds = $ReportAvail->getParsedBreakdownValue("warning","total","time","seconds");
				$DBHandler->insertAvailBreakdown($reportID, "warning", "total", "time", $orangeTotalTimeDays, $orangeTotalTimeHours, $orangeTotalTimeMinutes, $orangeTotalTimeSeconds);
				
				# ---===== Total Time =====---
				# Unscheduled
				my $orangeUnscheduledTotaltime = $ReportAvail->getParsedBreakdownValue("warning","unscheduled","totaltime");
				$DBHandler->insertAvailBreakdown($reportID, "warning", "unscheduled", "totaltime", $orangeUnscheduledTotaltime);
				
				# Scheduled
				my $orangeScheduledTotaltime = $ReportAvail->getParsedBreakdownValue("warning","scheduled","totaltime");
				$DBHandler->insertAvailBreakdown($reportID, "warning", "scheduled", "totaltime", $orangeScheduledTotaltime);
				
				# Total
				my $orangeTotalTotaltime = $ReportAvail->getParsedBreakdownValue("warning","total","totaltime");
				$DBHandler->insertAvailBreakdown($reportID, "warning", "total", "totaltime", $orangeTotalTotaltime);
				
				# ---===== Known Time =====---
				# Unscheduled
				my $orangeUnscheduledKnowntime = $ReportAvail->getParsedBreakdownValue("warning","unscheduled","knowntime");
				$DBHandler->insertAvailBreakdown($reportID, "warning", "unscheduled", "knowntime", $orangeUnscheduledKnowntime);
				
				# Scheduled
				my $orangeScheduledKnowntime = $ReportAvail->getParsedBreakdownValue("warning","scheduled","knowntime");
				$DBHandler->insertAvailBreakdown($reportID, "warning", "scheduled", "knowntime", $orangeScheduledKnowntime);
				
				# Total
				my $orangeTotalKnowntime = $ReportAvail->getParsedBreakdownValue("warning","total","knowntime");
				$DBHandler->insertAvailBreakdown($reportID, "warning", "total", "knowntime", $orangeTotalKnowntime);
			}
			
			
			# +------------------------------------------------------------------+
			# |                 Import UNKNOWN/UNREACHABLE state                 |
			# +------------------------------------------------------------------+
			$importState = 0;
			
			if ($ReportAvail->getReportType() eq "service") {
				$stateDefinition = "unknown";
				if ($Config->getParameter('SERVICEUNKNOWN') == 1) {
					$importState = 1;
					$Debug->addMessage("INFO: Importing service unknown data...", 1);
				}
			} else {
				$stateDefinition = "unreachable";
				if ($Config->getParameter('HOSTUNREACHABLE') == 1) {
					$importState = 1;
					$Debug->addMessage("INFO: Importing host unreachable data...", 1);
				}
			}
			
			if ($importState == 1) {
				# ---===== Time =====---
				# Unscheduled
				my $purpleUnscheduledTimeDays = $ReportAvail->getParsedBreakdownValue($stateDefinition,"unscheduled","time","days");
				my $purpleUnscheduledTimeHours = $ReportAvail->getParsedBreakdownValue($stateDefinition,"unscheduled","time","hours");
				my $purpleUnscheduledTimeMinutes = $ReportAvail->getParsedBreakdownValue($stateDefinition,"unscheduled","time","minutes");
				my $purpleUnscheduledTimeSeconds = $ReportAvail->getParsedBreakdownValue($stateDefinition,"unscheduled","time","seconds");
				$DBHandler->insertAvailBreakdown($reportID, $stateDefinition, "unscheduled", "time", $purpleUnscheduledTimeDays, $purpleUnscheduledTimeHours, $purpleUnscheduledTimeMinutes, $purpleUnscheduledTimeSeconds);
	
				# Scheduled
				my $purpleScheduledTimeDays = $ReportAvail->getParsedBreakdownValue($stateDefinition,"scheduled","time","days");
				my $purpleScheduledTimeHours = $ReportAvail->getParsedBreakdownValue($stateDefinition,"scheduled","time","hours");
				my $purpleScheduledTimeMinutes = $ReportAvail->getParsedBreakdownValue($stateDefinition,"scheduled","time","minutes");
				my $purpleScheduledTimeSeconds = $ReportAvail->getParsedBreakdownValue($stateDefinition,"scheduled","time","seconds");
				$DBHandler->insertAvailBreakdown($reportID, $stateDefinition, "scheduled", "time", $purpleScheduledTimeDays, $purpleScheduledTimeHours, $purpleScheduledTimeMinutes, $purpleScheduledTimeSeconds);
				
				# Total
				my $purpleTotalTimeDays = $ReportAvail->getParsedBreakdownValue($stateDefinition,"total","time","days");
				my $purpleTotalTimeHours = $ReportAvail->getParsedBreakdownValue($stateDefinition,"total","time","hours");
				my $purpleTotalTimeMinutes = $ReportAvail->getParsedBreakdownValue($stateDefinition,"total","time","minutes");
				my $purpleTotalTimeSeconds = $ReportAvail->getParsedBreakdownValue($stateDefinition,"total","time","seconds");
				$DBHandler->insertAvailBreakdown($reportID, $stateDefinition, "total", "time", $purpleTotalTimeDays, $purpleTotalTimeHours, $purpleTotalTimeMinutes, $purpleTotalTimeSeconds);
				
				# ---===== Total Time =====---
				# Unscheduled
				my $purpleUnscheduledTotaltime = $ReportAvail->getParsedBreakdownValue($stateDefinition,"unscheduled","totaltime");
				$DBHandler->insertAvailBreakdown($reportID, $stateDefinition, "unscheduled", "totaltime", $purpleUnscheduledTotaltime);
				
				# Scheduled
				my $purpleScheduledTotaltime = $ReportAvail->getParsedBreakdownValue($stateDefinition,"scheduled","totaltime");
				$DBHandler->insertAvailBreakdown($reportID, $stateDefinition, "scheduled", "totaltime", $purpleScheduledTotaltime);
				
				# Total
				my $purpleTotalTotaltime = $ReportAvail->getParsedBreakdownValue($stateDefinition,"total","totaltime");
				$DBHandler->insertAvailBreakdown($reportID, $stateDefinition, "total", "totaltime", $purpleTotalTotaltime);
				
				# ---===== Known Time =====---
				# Unscheduled
				my $purpleUnscheduledKnowntime = $ReportAvail->getParsedBreakdownValue($stateDefinition,"unscheduled","knowntime");
				$DBHandler->insertAvailBreakdown($reportID, $stateDefinition, "unscheduled", "knowntime", $purpleUnscheduledKnowntime);
				
				# Scheduled
				my $purpleScheduledKnowntime = $ReportAvail->getParsedBreakdownValue($stateDefinition,"scheduled","knowntime");
				$DBHandler->insertAvailBreakdown($reportID, $stateDefinition, "scheduled", "knowntime", $purpleScheduledKnowntime);
				
				# Total
				my $purpleTotalKnowntime = $ReportAvail->getParsedBreakdownValue($stateDefinition,"total","knowntime");
				$DBHandler->insertAvailBreakdown($reportID, $stateDefinition, "total", "knowntime", $purpleTotalKnowntime);
			}
			
			# +-----------------------------------------------------------+
			# |                 Insert CRITICAL/DOWN state                |
			# +-----------------------------------------------------------+
			$importState = 0;
			
			if ($ReportAvail->getReportType() eq "service") {
				$stateDefinition = "critical";
				if ($Config->getParameter('SERVICECRITICAL') == 1) {
					$importState = 1;
					$Debug->addMessage("INFO: Importing service critical data...", 1);
				}
			} else {
				$stateDefinition = "down";
				if ($Config->getParameter('HOSTDOWN') == 1) {
					$importState = 1;
					$Debug->addMessage("INFO: Importing host down data...", 1);
				}
			}
			
			if ($importState == 1) {
				# ---===== Time =====---
				# Unscheduled
				my $redUnscheduledTimeDays = $ReportAvail->getParsedBreakdownValue($stateDefinition,"unscheduled","time","days");
				my $redUnscheduledTimeHours = $ReportAvail->getParsedBreakdownValue($stateDefinition,"unscheduled","time","hours");
				my $redUnscheduledTimeMinutes = $ReportAvail->getParsedBreakdownValue($stateDefinition,"unscheduled","time","minutes");
				my $redUnscheduledTimeSeconds = $ReportAvail->getParsedBreakdownValue($stateDefinition,"unscheduled","time","seconds");
				$DBHandler->insertAvailBreakdown($reportID, $stateDefinition, "unscheduled", "time", $redUnscheduledTimeDays, $redUnscheduledTimeHours, $redUnscheduledTimeMinutes, $redUnscheduledTimeSeconds);
				
				# Scheduled
				my $redScheduledTimeDays = $ReportAvail->getParsedBreakdownValue($stateDefinition,"scheduled","time","days");
				my $redScheduledTimeHours = $ReportAvail->getParsedBreakdownValue($stateDefinition,"scheduled","time","hours");
				my $redScheduledTimeMinutes = $ReportAvail->getParsedBreakdownValue($stateDefinition,"scheduled","time","minutes");
				my $redScheduledTimeSeconds = $ReportAvail->getParsedBreakdownValue($stateDefinition,"scheduled","time","seconds");
				$DBHandler->insertAvailBreakdown($reportID, $stateDefinition, "scheduled", "time", $redScheduledTimeDays, $redScheduledTimeHours, $redScheduledTimeMinutes, $redScheduledTimeSeconds);
				
				# Total
				my $redTotalTimeDays = $ReportAvail->getParsedBreakdownValue($stateDefinition,"total","time","days");
				my $redTotalTimeHours = $ReportAvail->getParsedBreakdownValue($stateDefinition,"total","time","hours");
				my $redTotalTimeMinutes = $ReportAvail->getParsedBreakdownValue($stateDefinition,"total","time","minutes");
				my $redTotalTimeSeconds = $ReportAvail->getParsedBreakdownValue($stateDefinition,"total","time","seconds");
				$DBHandler->insertAvailBreakdown($reportID, $stateDefinition, "total", "time", $redTotalTimeDays, $redTotalTimeHours, $redTotalTimeMinutes, $redTotalTimeSeconds);
				
				# ---===== Total Time =====---
				# Unscheduled
				my $redUnscheduledTotaltime = $ReportAvail->getParsedBreakdownValue($stateDefinition,"unscheduled","totaltime");
				$DBHandler->insertAvailBreakdown($reportID, $stateDefinition, "unscheduled", "totaltime", $redUnscheduledTotaltime);
				
				# Scheduled
				my $redScheduledTotaltime = $ReportAvail->getParsedBreakdownValue($stateDefinition,"scheduled","totaltime");
				$DBHandler->insertAvailBreakdown($reportID, $stateDefinition, "scheduled", "totaltime", $redScheduledTotaltime);
				
				# Total
				my $redTotalTotaltime = $ReportAvail->getParsedBreakdownValue($stateDefinition,"total","totaltime");
				$DBHandler->insertAvailBreakdown($reportID, $stateDefinition, "total", "totaltime", $redTotalTotaltime);
				
				# ---===== Known Time =====---
				# Unscheduled
				my $redUnscheduledKnowntime = $ReportAvail->getParsedBreakdownValue($stateDefinition,"unscheduled","knowntime");
				$DBHandler->insertAvailBreakdown($reportID, $stateDefinition, "unscheduled", "knowntime", $redUnscheduledKnowntime);
				
				# Scheduled
				my $redScheduledKnowntime = $ReportAvail->getParsedBreakdownValue($stateDefinition,"scheduled","knowntime");
				$DBHandler->insertAvailBreakdown($reportID, $stateDefinition, "scheduled", "knowntime", $redScheduledKnowntime);
				
				# Total
				my $redTotalKnowntime = $ReportAvail->getParsedBreakdownValue($stateDefinition,"total","knowntime");
				$DBHandler->insertAvailBreakdown($reportID, $stateDefinition, "total", "knowntime", $redTotalKnowntime);
			}
			
			
			# +------------------------------------------------------+
			# |                 Insert Undetermined                  |
			# +------------------------------------------------------+
			if ($Config->getParameter('UNDETERMINED') == 1) {
				$Debug->addMessage("INFO: Importing undetermined data...", 1);
	
				# ---===== Not Running =====---
				# Time
				my $undeterminedNotRunningTimeDays = $ReportAvail->getParsedBreakdownValue("undetermined","notrunning","time","days");
				my $undeterminedNotRunningTimeHours = $ReportAvail->getParsedBreakdownValue("undetermined","notrunning","time","hours");
				my $undeterminedNotRunningTimeMinutes = $ReportAvail->getParsedBreakdownValue("undetermined","notrunning","time","minutes");
				my $undeterminedNotRunningTimeSeconds = $ReportAvail->getParsedBreakdownValue("undetermined","notrunning","time","seconds");
				$DBHandler->insertAvailBreakdown($reportID, "undetermined", "notrunning", "time", $undeterminedNotRunningTimeDays, $undeterminedNotRunningTimeHours, $undeterminedNotRunningTimeMinutes, $undeterminedNotRunningTimeSeconds);
				
				# Totaltime
				my $undeterminedNotRunningTotaltime = $ReportAvail->getParsedBreakdownValue("undetermined","notrunning","totaltime");
				$DBHandler->insertAvailBreakdown($reportID, "undetermined", "notrunning", "totaltime", $undeterminedNotRunningTotaltime);
				
				# ---===== Insufficient Data =====---
				# Time
				my $undeterminedInsufficientDataTimeDays = $ReportAvail->getParsedBreakdownValue("undetermined","insufficientdata","time","days");
				my $undeterminedInsufficientDataTimeHours = $ReportAvail->getParsedBreakdownValue("undetermined","insufficientdata","time","hours");
				my $undeterminedInsufficientDataTimeMinutes = $ReportAvail->getParsedBreakdownValue("undetermined","insufficientdata","time","minutes");
				my $undeterminedInsufficientDataTimeSeconds = $ReportAvail->getParsedBreakdownValue("undetermined","insufficientdata","time","seconds");
				$DBHandler->insertAvailBreakdown($reportID, "undetermined", "insufficientdata", "time", $undeterminedInsufficientDataTimeDays, $undeterminedInsufficientDataTimeHours, $undeterminedInsufficientDataTimeMinutes, $undeterminedInsufficientDataTimeSeconds);
				
				# Totaltime
				my $undeterminedInsufficientDataTotaltime = $ReportAvail->getParsedBreakdownValue("undetermined","insufficientdata","totaltime");
				$DBHandler->insertAvailBreakdown($reportID, "undetermined", "insufficientdata", "totaltime", $undeterminedInsufficientDataTotaltime);
				
				# ---===== Total =====---
				# Time
				my $undeterminedTotalTimeDays = $ReportAvail->getParsedBreakdownValue("undetermined","total","time","days");
				my $undeterminedTotalTimeHours = $ReportAvail->getParsedBreakdownValue("undetermined","total","time","hours");
				my $undeterminedTotalTimeMinutes = $ReportAvail->getParsedBreakdownValue("undetermined","total","time","minutes");
				my $undeterminedTotalTimeSeconds = $ReportAvail->getParsedBreakdownValue("undetermined","total","time","seconds");
				$DBHandler->insertAvailBreakdown($reportID, "undetermined", "total", "time", $undeterminedTotalTimeDays, $undeterminedTotalTimeHours, $undeterminedTotalTimeMinutes, $undeterminedTotalTimeSeconds);
				
				# Totaltime
				my $undeterminedTotalTotaltime = $ReportAvail->getParsedBreakdownValue("undetermined","total","totaltime");
				$DBHandler->insertAvailBreakdown($reportID, "undetermined", "total", "totaltime", $undeterminedTotalTotaltime);
			}
			
			
			# +------------------------------------------------------+
			# |                      Import All                      |
			# +------------------------------------------------------+
			if ($Config->getParameter('ALL') == 1) {
				$Debug->addMessage("INFO: Importing all data...", 1);
				
				# ---===== Total =====---
				# Time
				my $allTotalTimeDays = $ReportAvail->getParsedBreakdownValue("all","total","time","days");
				my $allTotalTimeHours = $ReportAvail->getParsedBreakdownValue("all","total","time","hours");
				my $allTotalTimeMinutes = $ReportAvail->getParsedBreakdownValue("all","total","time","minutes");
				my $allTotalTimeSeconds = $ReportAvail->getParsedBreakdownValue("all","total","time","seconds");
				$DBHandler->insertAvailBreakdown($reportID, "all", "total", "time", $allTotalTimeDays, $allTotalTimeHours, $allTotalTimeMinutes, $allTotalTimeSeconds);
				
				# Totaltime
				my $allTotalTotaltime = $ReportAvail->getParsedBreakdownValue("all","total","totaltime");
				$DBHandler->insertAvailBreakdown($reportID, "all", "total", "totaltime", $allTotalTotaltime);
				
				# Knowntime
				my $allTotalKnowntime = $ReportAvail->getParsedBreakdownValue("all","total","knowntime");
				$DBHandler->insertAvailBreakdown($reportID, "all", "total", "knowntime", $allTotalKnowntime);
			}
			
			
			# +------------------------------------------------------+
			# |                  Insert log entries                  |
			# +------------------------------------------------------+
			if ($Config->getParameter('LOGENTRIES') == 1) {
				$Debug->addMessage("INFO: Importing logentries data...", 1);

				my $allEventLogEntries = $ReportAvail->getParsedEventLogEntries();
				if (length($allEventLogEntries->{0}) != 0) {
					$DBHandler->insertAvailEventLogEntry($reportID,$allEventLogEntries);
				}
			}

			
			$Debug->addMessage("INFO: Report successfully created with ID ".$reportID." and parsed data imported!",1);
		}
		$Debug->close();
		$DBHandler->finishReport($reportID, $Debug->getExecutionTime(), $statusCode, "Report successfully created with ID ".$reportID." and parsed data imported!");
	}
}

# Exit
exit 0;

