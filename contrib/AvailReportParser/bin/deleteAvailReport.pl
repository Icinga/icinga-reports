#!/usr/bin/perl
=pod

=head1 NAME

 importAvailReport.pl - Import availibilty report from Icinga/Nagios to Mysql database
 
=head1 Version

Version 0.1.0

=head1 SYNOPSIS

 importDeleteReport.pl -I <ID> -c <config file>
 importDeleteReport.pl [-I|-c]

=head1 OPTIONS

=over 4

=item -I <ID> (required)

 ID from report

=item -c <config file> (optional: default 'default.ini')

 The configure file, which contains information about basic authentification to Icinga/Nagios, debugging etc.
 This script search config files in the folder ./etc. 

=back

=head1 AUTHOR

Michael Luebben <info@icinga.org>

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
use Getopt::Long;
use FindBin;
use lib "$FindBin::Bin/../include/modules";
use Database::DBHandler;
use Config::Configuration;
use Debug::Debugger;
use Data::Dumper;

my $optReportID;
my $optConfigFile;
my $result;
my $statusCode = "3";

# +------------------------------------------------------+
# |                     Starting.....                    |
# +------------------------------------------------------+
# Get arguments
Getopt::Long::Configure('bundling');
GetOptions(
	"I=i" =>	\$optReportID, 		"ID=i"				=> \$optReportID,		# required
	"c=s" =>	\$optConfigFile, 	"configfile=s"		=> \$optConfigFile	 	# optional (default: default.ini)
);
	
# Check arguments
if (!$optReportID) {
	print "No reporting ID!\n";
	exit 3;
}

# Set not defined arguments to default parameters
if (!$optConfigFile) {
	$optConfigFile = "default.ini"
}

# Read configuration file
my $Config = new Configuration($optConfigFile);


# Init debugger
my $Debug = new Debugger($Config->getParameter('DEBUGFILE'), $Config->getParameter('DEBUG'), $Config->getParameter('LOGLEVEL'));

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
	
	# Delete log entries from database
	$result = $DBHandler->deleteAvailEventLogEntry($optReportID);
	if ($result == 0) {
		$Debug->addMessage("INFO: Log entries with reporting ID ".$optReportID." successful deleted", 1);
	}
	
	# Delete breakdowns from database
	$result = $DBHandler->deleteAvailBreakdown($optReportID);
	if ($result == 0) {
		$Debug->addMessage("INFO: Breakdowns with reporting ID ".$optReportID." successful deleted", 1);
	}
	
	# Delete report from database
	$result = $DBHandler->deleteReport($optReportID);
	if ($result == 0) {
		$Debug->addMessage("INFO: Report with reporting ID ".$optReportID." successful deleted", 1);
	}
		
}
	
$Debug->close();
	

# Exit
exit 0;