package DBHandler;

use strict;
use DBI();
use Switch;
use Data::Dumper;

# Define table names
my $table_prefix = "icinga_";

my $tableStates = "states";
my $tableStatetypes = "statetypes";
my $tableTimetypes = "timetypes";
my $tableReasontypes = "reasontypes";
my $tableObjecttypes = "objecttypes";
my $tableAvailBreakdownsPercent = "raw_availability_breakdowns_percent";
my $tableAvailBreakdownsTime = "raw_availability_breakdowns_time";
my $tableAvailLogentries = "raw_availability_logentries";
my $tableReports = "reports";

=pod

=head1 NAME

DBHandler.pm

=head1 Version

Version 0.0.9

=head1 DESCRIPTION

Handles mysql database connection, import, export etc. for availability reporting.

=head1 SYNOPSIS

=head1 EXAMPLE

=head1 METHODS

=cut

# Constructor
sub new {
	my $pkg = shift;
	my $self = {};
	
	my ($dbHost, $dbName, $dbUser, $dbPass, $tablePrefix) = @_;
	
	$self->{table}->{states} = $tablePrefix.$tableStates;
	$self->{table}->{statetypes} = $tablePrefix.$tableStatetypes;
	$self->{table}->{timetypes} = $tablePrefix.$tableTimetypes;
	$self->{table}->{reasontypes} = $tablePrefix.$tableReasontypes;
	$self->{table}->{objecttypes} = $tablePrefix.$tableObjecttypes;
	$self->{table}->{raw_availability_breakdowns_percent} = $tablePrefix.$tableAvailBreakdownsPercent;
	$self->{table}->{raw_availability_breakdowns_time} = $tablePrefix.$tableAvailBreakdownsTime;
	$self->{table}->{raw_availability_logentries} = $tablePrefix.$tableAvailLogentries;
	$self->{table}->{reports} = $tablePrefix.$tableReports;
	
	$self->{dbh} = DBI->connect("DBI:mysql:database=$dbName;host=$dbHost","$dbUser","$dbPass");
	
	# Check if connection successful
	if (length($DBI::errstr) != 0) {
		$self->{errMessage} = "ERROR: ".$DBI::errstr;
		return -1;
	}
	
	bless $self, $pkg;
	return $self;
}


# Internal method for getAllStates
# Get all states from table states
sub getAllDatasFromTable {
	my $self = shift;
	my $table = shift;
	my $sth;
	my @result;
	
	switch ($table) {
		case "states" {
			$sth = $self->{dbh}->prepare("SELECT * FROM ".$self->{table}->{states});
		}
		case "statetypes" {
			$sth = $self->{dbh}->prepare("SELECT * FROM ".$self->{table}->{statetypes});
		}
		case "timetypes" {
			$sth = $self->{dbh}->prepare("SELECT * FROM ".$self->{table}->{timetypes});
		}
		case "reasontypes" {
			$sth = $self->{dbh}->prepare("SELECT * FROM ".$self->{table}->{reasontypes});
		}
		case "objecttypes" {
			$sth = $self->{dbh}->prepare("SELECT * FROM ".$self->{table}->{objecttypes});
		}
		else {
			$self->{errMessage} = "Table ".$table." not defined!";
			return -1;
		}
	}
	
	$sth->execute();
	
	while (@result = $sth->fetchrow_array()) {
		$self->{$table}->{@result[1]} = @result[0];
		$self->{$table}->{@result[0]} = @result[1];
	}

	$sth->finish;

	return 0;
}


=pod

=over

=item createNewReport()

Returns ID for a new report

=back

=head2 EXAMPLE

  $reportID = $DBHandler->createNewReport();

=cut
sub createNewReport {
	my $self = shift;
	my $hostname = shift;
	my $service_description = shift;
	my $report_description = shift;
	my $timeperiod = shift;
	my $rpttimeperiod = shift;
	my $config_filename = shift;
	
	my $sth;
	my $insertID;
		
	$sth = $self->{dbh}->prepare("INSERT INTO ".$self->{table}->{reports}." (date, hostname, service_description, report_description, timeperiod, rpttimeperiod, config_filename) VALUES (now(), '".$hostname."', '".$service_description."', '".$report_description."', '".$timeperiod."', '".$rpttimeperiod."', '".$config_filename."')");
	$sth->execute();
	$insertID = $self->{dbh}->{ q{mysql_insertid} };
	$sth->finish;
	
	if (length($insertID) == 0) {
		$self->{errMessage} = "Can't create new report";
		return -1
	} else {
		return $insertID;
	}
}


=pod

=over

=item finishReport(Report ID, paringDuration, exitStatus, lastMessages);

Finishes report after parsing

=back

=head2 EXAMPLE

  $reportID = $DBHandler->finishReport("1", "0.13388991355896", "0", "Report successfully created with ID 1");

=cut
sub finishReport {
	my $self = shift;
	my $reportID = shift;
	my $executionTime = shift;
	my $status = shift;
	my $message = shift;
	
	my $sth;
	
	$sth = $self->{dbh}->prepare("UPDATE ".$self->{table}->{reports}." SET execution_time = '".$executionTime."', exit_status = '".$status."', message = '".$message."' WHERE id = '".$reportID."'");
	$sth->execute();
	$sth->finish();
}


=pod

=over

=item getState()

Returns ID or state from table states

=back

=head2 EXAMPLE

  $DBHandler->getState("ok")

=cut
sub getState {
	my $self = shift;
	my $state = shift;
	
	if (length($self->{getAllDatasFromTable}->{result}->{states}) == 0) {
		$self->{getAllDatasFromTable}->{result}->{states} = $self->getAllDatasFromTable("states");
	}
	
	if ($self->{getAllDatasFromTable}->{result}->{states} == 0) {
		if (length($self->{states}->{$state}) == 0) {
			$self->{errMessage} = "State ".$state." not in table states found!";
			return -1
		} else {
			return $self->{states}->{$state};
		}
	} else {
		return -1;
	}
}


=pod

=over

=item getTimeType()

Returns ID or type from table timetypes

=back

=head2 EXAMPLE

  $DBHandler->getTimeType("time")

=cut
sub getTimeType {
	my $self = shift;
	my $type = shift;
	
	if (length($self->{getAllDatasFromTable}->{result}->{timetypes}) == 0) {
		$self->{getAllDatasFromTable}->{result}->{timetypes} = $self->getAllDatasFromTable("timetypes");
	}

	if ($self->{getAllDatasFromTable}->{result}->{timetypes} == 0) {
		if (length($self->{timetypes}->{$type}) == 0) {
			$self->{errMessage} = "Timetype ".$type." not in table timetypes found!";
			return -1
		} else {
			return $self->{timetypes}->{$type};
		}
	} else {
		return -1;
	}
}


=pod

=over

=item getReasonType()

Returns ID or type from table reasontypes

=back

=head2 EXAMPLE

  $DBHandler->getReasonType("notrunning")

=cut
sub getReasonType {
	my $self = shift;
	my $type = shift;
	
	if (length($self->{getAllDatasFromTable}->{result}->{reasontypes}) == 0) {
		$self->{getAllDatasFromTable}->{result}->{reasontypes} = $self->getAllDatasFromTable("reasontypes");
	}

	if ($self->{getAllDatasFromTable}->{result}->{reasontypes} == 0) {
		if (length($self->{reasontypes}->{$type}) == 0) {
			$self->{errMessage} = "Reasontype ".$type." not in table reasontypes found!";
			return -1
		} else {
			return $self->{reasontypes}->{$type};
		}
	} else {
		return -1;
	}
}


=pod

=over

=item getStateType()

Returns ID or type from table statetypes

=back

=head2 EXAMPLE

  $DBHandler->getStateType("SOFT")

=cut
sub getStateType {
	my $self = shift;
	my $type = shift;
	
	if (length($self->{getAllDatasFromTable}->{result}->{statetypes}) == 0) {
		$self->{getAllDatasFromTable}->{result}->{statetypes} = $self->getAllDatasFromTable("statetypes");
	}

	if ($self->{getAllDatasFromTable}->{result}->{statetypes} == 0) {
		if (length($self->{statetypes}->{$type}) == 0) {
			$self->{errMessage} = "Statetype ".$type." not in table statetypes found!";
			return -1
		} else {
			return $self->{statetypes}->{$type};
		}
	} else {
		return -1;
	}
}


=pod

=over

=item getObjecttype()

Returns ID or objecttype from table objecttypes

=back

=head2 EXAMPLE

  $DBHandler->getObjecttype("host")

=cut
sub getObjectType {
	my $self = shift;
	my $type = shift;

	if (length($self->{getAllDatasFromTable}->{result}->{objecttypes}) == 0) {
		$self->{getAllDatasFromTable}->{result}->{objecttypes} = $self->getAllDatasFromTable("objecttypes");
	}

	if ($self->{getAllDatasFromTable}->{result}->{objecttypes} == 0) {
		if (length($self->{objecttypes}->{$type}) == 0) {
			$self->{errMessage} = "Objecttype ".$type." not in table objecttypes found!";
			return -1
		} else {
			return $self->{objecttypes}->{$type};
		}
	} else {
		return -1;
	}
}


=pod

=over

=item insertAvailBreakdown(<reportID>, <state>, <timetypes>, <reasontypes>, <days>, <hours>, <minutes>, <seconds>, <percent>)

Insert tuple from breakdown availability report

=back

=head2 EXAMPLE

  $DBHandler->insertAvailBreakdown("1", "critical", "scheduled", "totaltime", "31", "00", "00", "00")
  
  or
  
  $DBHandler->insertAvailBreakdown("1", "critical", "scheduled", "time", "99,835")

=cut
sub insertAvailBreakdown {
	my $self = shift;
	my $reportID = shift;
	my $state = shift;
	my $reasonType = shift;
	my $timeType = shift;
	
	# Get ID's
	my $stateID = $self->getState($state);
	my $timeTypeID = $self->getTimeType($timeType);
	my $reasonTimeID = $self->getReasonType($reasonType);
	
	my $sth;
	my $insertID;
	
	switch ($timeType) {
		case "time" {
			my ($days, $hours, $minutes, $seconds) = @_;

			$sth = $self->{dbh}->prepare("INSERT INTO ".$self->{table}->{raw_availability_breakdowns_time}." (report_id, state_id, reasontype_id, timetype_id, days, hours, minutes, seconds) VALUES (".$reportID.", ".$stateID.",".$reasonTimeID.", ".$timeTypeID.", ".$days.", ".$hours.", ".$minutes.", ".$seconds.")");
			$sth->execute();
			$insertID = $self->{dbh}->{ q{mysql_insertid} };
			$sth->finish;
		
		}
		case "knowntime" {
			my ($percent) = @_;
			
			$sth = $self->{dbh}->prepare("INSERT INTO ".$self->{table}->{raw_availability_breakdowns_percent}." (report_id, state_id, reasontype_id, timetype_id, percent) VALUES (".$reportID.", ".$stateID.",".$reasonTimeID.", ".$timeTypeID.", ".$percent.")");
			$sth->execute();
			$insertID = $self->{dbh}->{ q{mysql_insertid} };
			$sth->finish;

		}
		case "totaltime" {
			my ($percent) = @_;
			
			$sth = $self->{dbh}->prepare("INSERT INTO ".$self->{table}->{raw_availability_breakdowns_percent}." (report_id, state_id, reasontype_id, timetype_id, percent) VALUES (".$reportID.", ".$stateID.",".$reasonTimeID.", ".$timeTypeID.", ".$percent.")");
			$sth->execute();
			$insertID = $self->{dbh}->{ q{mysql_insertid} };
			$sth->finish;
			
		}
		else {
			$self->{errMessage} = $timeType." not defined!";
			return -1;
		}
	}
	
	return 0;
}


# Internal method for insertAvailEventLogEntry
# Change Datetime format from eurapean format to english format
sub changeDatetype {
	my $self = shift;
	my $dateTime = shift;
	my $newDateTime;
	
	my @tmpDateTime = split(/ /,$dateTime);
	my @tmpDate = split (/-/, $tmpDateTime[0]);
	
	if (length($tmpDate[0]) == 2) {
		$newDateTime = $tmpDate[2]."-".$tmpDate[0]."-".$tmpDate[1]." ".$tmpDateTime[1];
	} elsif (length($tmpDate[0]) == 4) {
		$newDateTime = $dateTime;
	} else {
		$self->{errMessage} = "Wrong datetime format ".$dateTime;
		$newDateTime = -1;
	}
	
	return $newDateTime;
}


=pod

=over

=item insertAvailEventLogEntry(<reportID>, <Array with report tuple>)

Insert tuple from event log entries availability report

=back

=head2 EXAMPLE

  $DBHandler->insertAvailBreakdown("1", $allEventLogEntries)

=cut
sub insertAvailEventLogEntry {
        my $self = shift;
        my $reportID = shift;
        my $eventLogEntrys = shift;

        my $sth;
        my $insertID;
        my $index = 0;
 
        my $sql = "INSERT INTO ".$self->{table}->{raw_availability_logentries}." (report_id,
                                                                                  start_time,
                                                                                  stop_time,
                                                                                  duration_days,
                                                                                  duration_hours,
                                                                                  duration_minutes,
                                                                                  duration_seconds,
                                                                                  event_text,
                                                                                  objecttype_id,
                                                                                  state_id,
                                                                                  statetype_id,
                                                                                  state_information) VALUES ";

        while (length($eventLogEntrys->{$index}) != 0) {
                my $eventLogEntry = $eventLogEntrys->{$index};

                my $objecttype = $eventLogEntry->{state}->{objecttype};
                my $state = $eventLogEntry->{state}->{state};
                my $stateType = $eventLogEntry->{state}->{type};

                $sql .= "(".$reportID.", '".$self->changeDatetype($eventLogEntry->{starttime})."', '".$self->changeDatetype($eventLogEntry->{stoptime})."', ".$eventLogEntry->{duration}->{days}.", ".$eventLogEntry->{duration}->{hours}.", ".$eventLogEntry->{duration}->{minutes}.", ".$eventLogEntry->{duration}->{seconds}.", '".$eventLogEntry->{eventtext}."', ".$self->getObjectType($objecttype).", ".$self->getState($state).", ".$self->getStateType($stateType).", '".$eventLogEntry->{stateinformation}."'),";
                ++$index;
        }

        $sth = $self->{dbh}->prepare(substr($sql, 0, -1));


        $sth->execute();
        $insertID = $self->{dbh}->{ q{mysql_insertid} };
        $sth->finish;

        return $insertID;
}


=pod

=over

=item deleteAvailBreakdown(<reportID>)

Delete all tuples from breakdown availability report

=back

=head2 EXAMPLE

  $DBHandler->deleteAvailBreakdown("1")

=cut
sub deleteAvailBreakdown {
    my $self = shift;
	my $reportID = shift;
	my $sth;
	my $sql;

 
	$sql = "DELETE FROM ".$self->{table}->{raw_availability_breakdowns_time}." WHERE report_id = ".$reportID;
	$sth = $self->{dbh}->prepare($sql);
	$sth->execute();
        
	$sql = "DELETE FROM ".$self->{table}->{raw_availability_breakdowns_percent}." WHERE report_id = ".$reportID;
	$sth = $self->{dbh}->prepare($sql);
    $sth->execute();
        
	$sth->finish;

	return 0;
}


=pod

=over

=item deleteAvailEventLogEntry(<reportID>)

Delete all tuples from event log entries availability report

=back

=head2 EXAMPLE

  $DBHandler->deleteAvailEventLogEntry("1")

=cut
sub deleteAvailEventLogEntry {
        my $self = shift;
        my $reportID = shift;

        my $sth;

 
        my $sql = "DELETE FROM ".$self->{table}->{raw_availability_logentries}." WHERE report_id = ".$reportID;


        $sth = $self->{dbh}->prepare($sql);


        $sth->execute();
        $sth->finish;

        return 0;
}

=pod

=over

=item deleteReport(<reportID>)

Delete report from database

=back

=head2 EXAMPLE

  $DBHandler->deleteReport("1");

=cut
sub deleteReport {
	my $self = shift;
	my $reportID = shift;
	my $sth;
 
	my $sql = "DELETE FROM ".$self->{table}->{reports}." WHERE id = ".$reportID;

	$sth = $self->{dbh}->prepare($sql);


	$sth->execute();
	$sth->finish;

	return 0;
}


=pod

=over

=item close()

Close database connection

=back

=head2 EXAMPLE

  $DBHandler->close()

=cut
sub close {
	my $self = shift;
	
	$self->{dbh}->disconnect;
	
	return 0;
}


=pod

=over

=item getErrorMessage()

Returns error message from object

=back

=head2 EXAMPLE

  $DBHandler->getErrorMessage()

=cut
sub getErrorMessage {
	my $self = shift;
	
	return $self->{errMessage};	
}


1;

=head1 REQUIRES

Perl 5, strict, DBI, Switch

=head1 AUTHOR

Michael Luebben <info@icinga.org>

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

=head1 History

=cut