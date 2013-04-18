package Availability;

use strict;
use Getopt::Long;
use HTML::Parser;
use Switch;
use JSON;
use Data::Dumper;

=pod

=head1 NAME

Availability.pm

=head1 Version

Version 0.1.2

=head1 DESCRIPTION

This module get and parse the availalibilty report for a host or service from Icinga/Nagios.

=head1 SYNOPSIS

  use Availability;
  
  my $ReportAvail = new Availability();
  
  $ReportAvail->setUrlParameter('host',$host);
  
  my $host = $ReportAvail->getUrlParameter('host','test');

  $ReportAvail->setUrlPath($urlPath);
  
  my $url = $ReportAvail->getUrl();
  
  $ReportAvail->parseContent(<html content>);
  
  my $result = $ReportAvail->getParsedValue($state, $type, $time);
  
=head1 EXAMPLE

  use strict;
  use LWP 5.64;
  use Reporting::Availability;
  
  my $ReportAvail = new Availability();
  
  # Get arguments
  Getopt::Long::Configure('bundling');
  GetOptions(
	"H=s" =>	\$opt_H, "hostname=s"		=> \$opt_H,
	"S=s" =>	\$opt_S, "services=s"		=> \$opt_S,
	"T=s" =>	\$opt_T, "timeperiod=s"		=> \$opt_T
  );

  # Set parameters for url
  $ReportAvail->setUrlParameter('host',$opt_H);
  $ReportAvail->setUrlParameter('service',$opt_S);
  $ReportAvail->setUrlParameter('timeperiod',$opt_T);
  
  # Get url for availibility report
  $ReportAvail->setUrlPath("http://localhost/icinga/");
  my $url = $ReportAvail->getUrl();
  
  # Get availalibility report from Icinga/Nagios
  my $Browser = LWP::UserAgent->new;
  $Browser->credentials(
	"localhost:80",
	"Icinga Access",
	"Username" => "Password")
  );
  my $response = $Browser->get($url);
  
  # Parse HTML content
  $ReportAvail->parseContent($response->content);

  print $ReportAvail->getParsedValue("ok","unscheduled","time" );

=head1 METHODS

=cut

# Constructor
sub new {
	my $pkg = shift;
	my $self = {};
	$self->{errMessage} = "No errors!";

	$self->{url}->{param}->{index}->{show_log_entries} = "0";
	$self->{url}->{param}->{name}->{0} = "show_log_entries";
	$self->{url}->{param}->{value}->{0} = "";
	
	$self->{url}->{param}->{index}->{host} = "1";
	$self->{url}->{param}->{name}->{1} = "host";
	$self->{url}->{param}->{value}->{1} = "";
	
	$self->{url}->{param}->{index}->{service} = "2";
	$self->{url}->{param}->{name}->{2} = "service";
	$self->{url}->{param}->{value}->{2} = "";
	
	$self->{url}->{param}->{index}->{timeperiod} = "3";	
	$self->{url}->{param}->{name}->{3} = "timeperiod";
	$self->{url}->{param}->{value}->{3} = "lastmonth";
	
	$self->{url}->{param}->{index}->{smon} = "4";	
	$self->{url}->{param}->{name}->{4} = "smon";
	$self->{url}->{param}->{value}->{4} = "7";
	
	$self->{url}->{param}->{index}->{sday} = "5";	
	$self->{url}->{param}->{name}->{5} = "sday";
	$self->{url}->{param}->{value}->{5} = "1";
	
	$self->{url}->{param}->{index}->{syear} = "6";	
	$self->{url}->{param}->{name}->{6} = "syear";
	$self->{url}->{param}->{value}->{6} = "2010";
	
	$self->{url}->{param}->{index}->{shour} = "7";	
	$self->{url}->{param}->{name}->{7} = "shour";
	$self->{url}->{param}->{value}->{7} = "0";
	
	$self->{url}->{param}->{index}->{smin} = "8";	
	$self->{url}->{param}->{name}->{8} = "smin";
	$self->{url}->{param}->{value}->{8} = "0";
	
	$self->{url}->{param}->{index}->{ssec} = "9";	
	$self->{url}->{param}->{name}->{9} = "ssec";
	$self->{url}->{param}->{value}->{9} = "0";
	
	$self->{url}->{param}->{index}->{emon} = "10";	
	$self->{url}->{param}->{name}->{10} = "emon";
	$self->{url}->{param}->{value}->{10} = "7";
	
	$self->{url}->{param}->{index}->{eday} = "11";	
	$self->{url}->{param}->{name}->{11} = "eday";
	$self->{url}->{param}->{value}->{11} = "13";
	
	$self->{url}->{param}->{index}->{eyear} = "12";	
	$self->{url}->{param}->{name}->{12} = "eyear";
	$self->{url}->{param}->{value}->{12} = "2010";
	
	$self->{url}->{param}->{index}->{ehour} = "13";	
	$self->{url}->{param}->{name}->{13} = "ehour";
	$self->{url}->{param}->{value}->{13} = "24";
	
	$self->{url}->{param}->{index}->{emin} = "14";	
	$self->{url}->{param}->{name}->{14} = "emin";
	$self->{url}->{param}->{value}->{14} = "0";
	
	$self->{url}->{param}->{index}->{esec} = "15";	
	$self->{url}->{param}->{name}->{15} = "esec";
	$self->{url}->{param}->{value}->{15} = "0";
		
	$self->{url}->{param}->{index}->{rpttimeperiod} = "16";	
	$self->{url}->{param}->{name}->{16} = "rpttimeperiod";
	$self->{url}->{param}->{value}->{16} = "";
	
	$self->{url}->{param}->{index}->{assumeinitialstates} = "17";
	$self->{url}->{param}->{name}->{17} = "assumeinitialstates";
	$self->{url}->{param}->{value}->{17} = "yes";
	
	$self->{url}->{param}->{index}->{assumestateretention} = "18";	
	$self->{url}->{param}->{name}->{18} = "assumestateretention";
	$self->{url}->{param}->{value}->{18} = "yes";
	
	$self->{url}->{param}->{index}->{assumestatesduringnotrunning} = "19";	
	$self->{url}->{param}->{name}->{19} = "assumestatesduringnotrunning";
	$self->{url}->{param}->{value}->{19} = "yes";
	
	$self->{url}->{param}->{index}->{includesoftstates} = "20";
	$self->{url}->{param}->{name}->{20} = "includesoftstates";
	$self->{url}->{param}->{value}->{20} = "no";
	
	$self->{url}->{param}->{index}->{initialassumedservicestate} = "21";	
	$self->{url}->{param}->{name}->{21} = "initialassumedservicestate";
	$self->{url}->{param}->{value}->{21} = "0";
	
	$self->{url}->{param}->{index}->{backtrack} = "22";	
	$self->{url}->{param}->{name}->{22} = "backtrack";
	$self->{url}->{param}->{value}->{22} = "0";
	
	$self->{parser}->{type} = "HTML";
	
	bless $self, $pkg;
	return $self;
}


=pod

=over

=item setUrlPath()

Set the first part from url.

=back

=head2 EXAMPLE

  $Avail->setUrlPath("http://localhost/icinga/")

=cut
sub setUrlPath {
	my $self = shift;
	my $urlPath = shift;
	
	$self->{url}->{path} = $urlPath; 
	
	return 0
}


=pod

=over

=item setUrlParameter()

Set parameter for url.

=over

B<List of url parameters:>

 - host				=> Hostname
 - service			=> Service description
 - rpttimeperiod		=> Report time period
 - assumeinitialstates		=> Assume initail states (yes/no) Default: yes
 - assumestateretention		=> Assume state retention (yes/no) Default: yes
 - assumestatesduringnotrunning => Assume states during program downtime (yes/no) Default: yes
 - includesoftstates 		=> Include Soft States (yes/no) Default: no
 - backtrack			=> Backtracked Archives (To Scan For Initial States) Default: 0
 - initialassumedservicestate	=> First Assumed Service State

=over

B<Defined service states>

 *  0	=> Unspecified
 * -1	=> Current state
 *  6	=> Service ok
 *  7	=> Service warning
 *  8	=> Service unknown
 *  9 	=> Service critical

=back

 - timeperiod			=> <Use defined timeperiods>
 
=over

B<Defined timeperiods>

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

=over

B<Parameters for custom period report>

 * smon	 => Starttime month <mm>
 * sday	 => Starttime day <dd>
 * syear => Starttime year <yyyy>
 * emon	 => Endtime month <mm>
 * eday	 => Endtime day <dd>
 * eyear => Endtime year <yyyy>

=back

=back

=back

=back
 
=head2 EXAMPLE

  $Avail->setParameterUrl("timeperiod","lastyear")

=cut
sub setUrlParameter {
	my $self = shift;
	my ($name, $value) = @_;
	my $exitCode = 0;
	
	# Get index
	my $index = $self->getIndex($name);

	# Check if the name is valid
	if ($index == -1) {
		$self->{errMessage} = "setUrlParameter(): ".$self->{errMessage};
		return $index;
	} else {
		# Check if the value is valid
		switch ($name) {
			case "host" {
				return $self->{url}->{param}->{value}->{$index} = $value;
			}
			case "service" {
				return $self->{url}->{param}->{value}->{$index} = $value;
			}
			case "rpttimeperiod" {
				if (length($value) != 0) {
					return $self->{url}->{param}->{value}->{$index} = $value;
				} else {
					$self->{errMessage} = "setUrlParameter(): ".$value." is not a allowed value for the parameter ".$name."!";
					return -1;
				}
			}
			case "assumeinitialstates" {
				if ($value eq "yes" || $value eq "no") {
					return $self->{url}->{param}->{value}->{$index} = $value;
				} else {
					$self->{errMessage} = "setUrlParameter(): ".$value." is not a allowed value for the parameter ".$name."!";
					return -1;
				}
			}
			case "assumestateretention" {
				if ($value eq "yes" || $value eq "no") {
					return $self->{url}->{param}->{value}->{$index} = $value;
				} else {
					$self->{errMessage} = "setUrlParameter(): ".$value." is not a allowed value for the parameter ".$name."!";
					return -1;
				}
			}
			case "assumestatesduringnotrunning" {
				if ($value eq "yes" || $value eq "no") {
					return $self->{url}->{param}->{value}->{$index} = $value;
				} else {
					$self->{errMessage} = "setUrlParameter(): ".$value." is not a allowed value for the parameter ".$name."!";
					return -1;
				}
			}
			case "includesoftstates" {
				if ($value eq "yes" || $value eq "no") {
					return $self->{url}->{param}->{value}->{$index} = $value;
				} else {
					$self->{errMessage} = "setUrlParameter(): ".$value." is not a allowed value for the parameter ".$name."!";
					return -1;
				}
			}
			case "backtrack" {
				if ($value =~ y/0-9//) {
					return $self->{url}->{param}->{value}->{$index} = $value;
				} else {
					$self->{errMessage} = "setUrlParameter(): ".$value." is not a allowed value for the parameter ".$name."!";
					return -1;
				}
			}
			case "initialassumedservicestate" {
				if ($value == "0" || $value == "-1" || $value == "6" || $value == "7" || $value == "8" || $value == "9") {
					return $self->{url}->{param}->{value}->{$index} = $value;
				} else {
					$self->{errMessage} = "setUrlParameter(): ".$value." is not a allowed value for the parameter ".$name."!";
					return -1;
				}
			}
			case "timeperiod" {
				if (length($value) == 0 ||$value eq "today" || $value eq "last24hours" || $value eq "yesterday" || $value eq "thisweek" || $value eq "last7days" || $value eq "lastweek" || $value eq "last31days" || $value eq "thismonth" || $value eq "lastmonth" || $value eq "thisyear" || $value eq "lastyear" || $value eq "custom") {
					return $self->{url}->{param}->{value}->{$index} = $value;
				} else {
					$self->{errMessage} = "setUrlParameter(): ".$value." is not a allowed value for the parameter ".$name."!";
					return -1;
				}
			}
			case "smon" {
				if ($value =~ y/0-9//) {
					print $value;
					return $self->{url}->{param}->{value}->{$index} = $value;
				} else {
					$self->{errMessage} = "setUrlParameter(): ".$value." is not a allowed value for the parameter ".$name."!";
					return -1;
				}
			}
			case "sday" {
				if ($value =~ y/0-9//) {
					print $value;
					return $self->{url}->{param}->{value}->{$index} = $value;
				} else {
					$self->{errMessage} = "setUrlParameter(): ".$value." is not a allowed value for the parameter ".$name."!";
					return -1;
				}
			}
			case "syear" {
				if ($value =~ y/0-9//) {
					print $value;
					return $self->{url}->{param}->{value}->{$index} = $value;
				} else {
					$self->{errMessage} = "setUrlParameter(): ".$value." is not a allowed value for the parameter ".$name."!";
					return -1;
				}
			}
			case "emon" {
				if ($value =~ y/0-9//) {
					print $value;
					return $self->{url}->{param}->{value}->{$index} = $value;
				} else {
					$self->{errMessage} = "setUrlParameter(): ".$value." is not a allowed value for the parameter ".$name."!";
					return -1;
				}
			}
			case "eday" {
				if ($value =~ y/0-9//) {
					print $value;
					return $self->{url}->{param}->{value}->{$index} = $value;
				} else {
					$self->{errMessage} = "setUrlParameter(): ".$value." is not a allowed value for the parameter ".$name."!";
					return -1;
				}
			}
			case "eyear" {
				if ($value =~ y/0-9//) {
					print $value;
					return $self->{url}->{param}->{value}->{$index} = $value;
				} else {
					$self->{errMessage} = "setUrlParameter(): ".$value." is not a allowed value for the parameter ".$name."!";
					return -1;
				}
			}
		}
	}
}


=pod

=over

=item setParserType()

Set the parser type to HTML or JSON. Default: HTML

=back

=head2 EXAMPLE

  my $urlParameter = $Avail->setParserType("JSON")

=cut
sub setParserType {
	my $self = shift;
	my $parserType = shift;
	
	if ($parserType eq "HTML") {
		$self->{parser}->{type} = "HTML";
		return 0
	} elsif ($parserType eq "JSON") {
		$self->{parser}->{type} = "JSON";
		return 0
	} else {
		$self->{errMessage} = $parserType." is not a allowed parser type!";
		return -1;
	}
}


=pod

=over

=item getUrlParameter()

Returns value from url parameter.

=back

=head2 EXAMPLE

  my $urlParameter = $Avail->getParameterUrl("timeperiod")

=cut
sub getUrlParameter {
	my $self = shift;
	my ($name) = @_;
	
	# Get index
	my $index = $self->getIndex($name);
	
	if ($index == -1) {
		$self->{errMessage} = "getUrlParameter(): ".$self->{errMessage};
		return $index;
	} else {
		return $self->{url}->{param}->{value}->{$index};
	}
}


# Internal method for setUrlParameter() and getUrlParameter()
# Returns the index from parameter name
sub getIndex {
	my $self = shift;
	my ($name) = @_;
	
	# Check if parameter name exits
	if (length($self->{url}->{param}->{index}->{$name}) != 0) {
		return $self->{url}->{param}->{index}->{$name}
	}
	
	$self->{errMessage} = $name." is not a allowed parameter name!";
	return -1;
}


=pod

=over

=item getReportType()

Returns the report type host or service

=back

=head2 EXAMPLE

  $Avail->getReportType()

=cut
sub getReportType {
	my $self = shift;
	
	if (length($self->getUrlParameter("service")) == 0) {
		$self->{report}->{type} = "host";	
	} else {
		$self->{report}->{type} = "service";
	}
	
	return $self->{report}->{type};
}


=pod

=over

=item getUrl()

Create and returns a url to get avialalibilty report

=back

=head2 EXAMPLE

  my $url = $Avail->getUrl()

=cut
sub getUrl {
	my $self = shift;
	my $seperator = "";
	my $result = "";
	
	if (length($self->{url}->{path}) != 0) {
		$self->{url}->{url} = $self->{url}->{path}."cgi-bin/avail.cgi?";
		
		if (length($self->{url}->{param}->{name}->{2}) == 0) {
			
		}
		 
		for (my $index=0;$index <= 22;$index++) {
			if ($index == 1) {
				$seperator = "&"
			}
			
			# If host availibility report, ignore service parameter in url
			if ($index == 2) {
				if (length($self->{url}->{param}->{value}->{$index}) != 0) {
					$self->{url}->{url} .= $seperator.$self->{url}->{param}->{name}->{$index}."=".$self->{url}->{param}->{value}->{$index};
				}
			} else {
				$self->{url}->{url} .= $seperator.$self->{url}->{param}->{name}->{$index}."=".$self->{url}->{param}->{value}->{$index};
			}
		}
		$result = $self->{url}->{url};
	} else {
		$result = "You musst first set the url path!"	
	}
	
	if ($self->{parser}->{type} eq "JSON") {
		return $result."&jsonoutput";
	} else {
		return $result;
	}
}


=pod

=over

=item parseContent()

Parse HTML content from availability report.

=back

=head2 EXAMPLE

  $Avail->parseContent()

=cut
sub parseContent {
	my $self = shift;
	my $content = shift;
	
	# Check if availibility report for host or service
	if (length($self->getUrlParameter("service")) == 0) {
		$self->{report}->{type} = "host";	
	} else {
		$self->{report}->{type} = "service";
	}
	
	# HTML parsing for service availability
	if ($self->{parser}->{type} eq  "HTML") {
		my $Parser = HTML::Parser->new(
			api_version => 3,
		);
		$Parser->handler("start" => \&startHandler, "tagname, attr, self");
		my $parsed = $Parser->parse($content);
		
		# For service availability
		if ($self->{report}->{type} eq "service") {
			if (length($parsed->{element}[20][1]) == 0) {
				$self->{errMessage} = "No HTML content for parsing found! Icinga/Nagios running?";
				return -1;
			} else {
				$self->{service}->{ok}->{unscheduled}->{time} = $self->splitTime($parsed->{element}[19][1]);
				$self->{service}->{ok}->{unscheduled}->{totaltime} = substr($parsed->{element}[20][1],0,-1);
				$self->{service}->{ok}->{unscheduled}->{knowntime} = substr($parsed->{element}[21][1],0,-1);
				
				$self->{service}->{ok}->{scheduled}->{time} = $self->splitTime($parsed->{element}[23][1]);
				$self->{service}->{ok}->{scheduled}->{totaltime} = substr($parsed->{element}[24][1],0,-1);
				$self->{service}->{ok}->{scheduled}->{knowntime} = substr($parsed->{element}[25][1],0,-1);
				
				$self->{service}->{ok}->{total}->{time} = $self->splitTime($parsed->{element}[27][1]);
				$self->{service}->{ok}->{total}->{totaltime} = substr($parsed->{element}[28][1],0,-1);
				$self->{service}->{ok}->{total}->{knowntime} = substr($parsed->{element}[29][1],0,-1);
				
				
				$self->{service}->{warning}->{unscheduled}->{time} = $self->splitTime($parsed->{element}[32][1]);
				$self->{service}->{warning}->{unscheduled}->{totaltime} = substr($parsed->{element}[33][1],0,-1);
				$self->{service}->{warning}->{unscheduled}->{knowntime} = substr($parsed->{element}[34][1],0,-1);
				
				$self->{service}->{warning}->{scheduled}->{time} = $self->splitTime($parsed->{element}[36][1]);
				$self->{service}->{warning}->{scheduled}->{totaltime} = substr($parsed->{element}[37][1],0,-1);
				$self->{service}->{warning}->{scheduled}->{knowntime} = substr($parsed->{element}[38][1],0,-1);
				
				$self->{service}->{warning}->{total}->{time} = $self->splitTime($parsed->{element}[40][1]);
				$self->{service}->{warning}->{total}->{totaltime} = substr($parsed->{element}[41][1],0,-1);
				$self->{service}->{warning}->{total}->{knowntime} = substr($parsed->{element}[42][1],0,-1);
				
				
				$self->{service}->{unknown}->{unscheduled}->{time} = $self->splitTime($parsed->{element}[45][1]);
				$self->{service}->{unknown}->{unscheduled}->{totaltime} = substr($parsed->{element}[46][1],0,-1);
				$self->{service}->{unknown}->{unscheduled}->{knowntime} = substr($parsed->{element}[47][1],0,-1);
				
				$self->{service}->{unknown}->{scheduled}->{time} = $self->splitTime($parsed->{element}[49][1]);
				$self->{service}->{unknown}->{scheduled}->{totaltime} = substr($parsed->{element}[50][1],0,-1);
				$self->{service}->{unknown}->{scheduled}->{knowntime} = substr($parsed->{element}[51][1],0,-1);
				
				$self->{service}->{unknown}->{total}->{time} = $self->splitTime($parsed->{element}[53][1]);
				$self->{service}->{unknown}->{total}->{totaltime} = substr($parsed->{element}[54][1],0,-1);
				$self->{service}->{unknown}->{total}->{knowntime} = substr($parsed->{element}[54][1],0,-1);
				
				
				$self->{service}->{critical}->{unscheduled}->{time} = $self->splitTime($parsed->{element}[58][1]);
				$self->{service}->{critical}->{unscheduled}->{totaltime} = substr($parsed->{element}[59][1],0,-1);
				$self->{service}->{critical}->{unscheduled}->{knowntime} = substr($parsed->{element}[60][1],0,-1);
				
				$self->{service}->{critical}->{scheduled}->{time} = $self->splitTime($parsed->{element}[62][1]);
				$self->{service}->{critical}->{scheduled}->{totaltime} = substr($parsed->{element}[63][1],0,-1);
				$self->{service}->{critical}->{scheduled}->{knowntime} = substr($parsed->{element}[64][1],0,-1);
				
				$self->{service}->{critical}->{total}->{time} = $self->splitTime($parsed->{element}[66][1]);
				$self->{service}->{critical}->{total}->{totaltime} = substr($parsed->{element}[67][1],0,-1);
				$self->{service}->{critical}->{total}->{knowntime} = substr($parsed->{element}[68][1],0,-1);
					
				
				$self->{service}->{undetermined}->{notrunning}->{time} = $self->splitTime($parsed->{element}[71][1]);
				$self->{service}->{undetermined}->{notrunning}->{totaltime} = substr($parsed->{element}[72][1],0,-1);
				
				$self->{service}->{undetermined}->{insufficientdata}->{time} = $self->splitTime($parsed->{element}[75][1]);
				$self->{service}->{undetermined}->{insufficientdata}->{totaltime} = substr($parsed->{element}[76][1],0,-1);
				
				$self->{service}->{undetermined}->{total}->{time} = $self->splitTime($parsed->{element}[79][1]);
				$self->{service}->{undetermined}->{total}->{totaltime} = substr($parsed->{element}[80][1],0,-1);
				
				
				$self->{service}->{all}->{total}->{time} = $self->splitTime($parsed->{element}[85][1]);
				$self->{service}->{all}->{total}->{totaltime} = substr($parsed->{element}[86][1],0,-1);
				$self->{service}->{all}->{total}->{knowntime} = substr($parsed->{element}[87][1],0,-1);
			
				
				# Service Log Entries
				my $logParserIndex = 87;
				my $logIndex = 0;
				while (length($parsed->{element}[$logParserIndex+1][1]) != 0) {
					$self->{service}->{logentries}->{event}->{$logIndex}->{starttime} = $parsed->{element}[++$logParserIndex][1];
					$self->{service}->{logentries}->{event}->{$logIndex}->{stoptime} = $parsed->{element}[++$logParserIndex][1];
					$self->{service}->{logentries}->{event}->{$logIndex}->{duration} = $self->splitTime($parsed->{element}[++$logParserIndex][1]);
					$self->{service}->{logentries}->{event}->{$logIndex}->{eventtext} = $parsed->{element}[++$logParserIndex][1];
					$self->{service}->{logentries}->{event}->{$logIndex}->{state} = $self->splitStateType($parsed->{element}[$logParserIndex][1]);
					$self->{service}->{logentries}->{event}->{$logIndex}->{stateinformation} = $parsed->{element}[++$logParserIndex][1];
					++$logIndex;
				}
				
				return 0;
			} # End html service parsing
		} else {
			# For host availability
			if (length($parsed->{element}[20][1]) == 0) {
				$self->{errMessage} = "No HTML content for parsing found! Icinga/Nagios running?";
				return -1;
			} else {
				$self->{host}->{up}->{unscheduled}->{time} = $self->splitTime($parsed->{element}[19][1]);
				$self->{host}->{up}->{unscheduled}->{totaltime} = substr($parsed->{element}[20][1],0,-1);
				$self->{host}->{up}->{unscheduled}->{knowntime} = substr($parsed->{element}[21][1],0,-1);
				
				$self->{host}->{up}->{scheduled}->{time} = $self->splitTime($parsed->{element}[23][1]);
				$self->{host}->{up}->{scheduled}->{totaltime} = substr($parsed->{element}[24][1],0,-1);
				$self->{host}->{up}->{scheduled}->{knowntime} = substr($parsed->{element}[25][1],0,-1);
				
				$self->{host}->{up}->{total}->{time} = $self->splitTime($parsed->{element}[27][1]);
				$self->{host}->{up}->{total}->{totaltime} = substr($parsed->{element}[28][1],0,-1);
				$self->{host}->{up}->{total}->{knowntime} = substr($parsed->{element}[29][1],0,-1);
				
				
				$self->{host}->{down}->{unscheduled}->{time} = $self->splitTime($parsed->{element}[32][1]);
				$self->{host}->{down}->{unscheduled}->{totaltime} = substr($parsed->{element}[33][1],0,-1);
				$self->{host}->{down}->{unscheduled}->{knowntime} = substr($parsed->{element}[34][1],0,-1);
				
				$self->{host}->{down}->{scheduled}->{time} = $self->splitTime($parsed->{element}[36][1]);
				$self->{host}->{down}->{scheduled}->{totaltime} = substr($parsed->{element}[37][1],0,-1);
				$self->{host}->{down}->{scheduled}->{knowntime} = substr($parsed->{element}[38][1],0,-1);
				
				$self->{host}->{down}->{total}->{time} = $self->splitTime($parsed->{element}[40][1]);
				$self->{host}->{down}->{total}->{totaltime} = substr($parsed->{element}[41][1],0,-1);
				$self->{host}->{down}->{total}->{knowntime} = substr($parsed->{element}[42][1],0,-1);
				
				
				$self->{host}->{unreachable}->{unscheduled}->{time} = $self->splitTime($parsed->{element}[45][1]);
				$self->{host}->{unreachable}->{unscheduled}->{totaltime} = substr($parsed->{element}[46][1],0,-1);
				$self->{host}->{unreachable}->{unscheduled}->{knowntime} = substr($parsed->{element}[47][1],0,-1);
				
				$self->{host}->{unreachable}->{scheduled}->{time} = $self->splitTime($parsed->{element}[49][1]);
				$self->{host}->{unreachable}->{scheduled}->{totaltime} = substr($parsed->{element}[50][1],0,-1);
				$self->{host}->{unreachable}->{scheduled}->{knowntime} = substr($parsed->{element}[51][1],0,-1);
				
				$self->{host}->{unreachable}->{total}->{time} = $self->splitTime($parsed->{element}[53][1]);
				$self->{host}->{unreachable}->{total}->{totaltime} = substr($parsed->{element}[54][1],0,-1);
				$self->{host}->{unreachable}->{total}->{knowntime} = substr($parsed->{element}[54][1],0,-1);
				
				
				$self->{host}->{undetermined}->{notrunning}->{time} = $self->splitTime($parsed->{element}[58][1]);
				$self->{host}->{undetermined}->{notrunning}->{totaltime} = substr($parsed->{element}[59][1],0,-1);
				
				$self->{host}->{undetermined}->{insufficientdata}->{time} = $self->splitTime($parsed->{element}[62][1]);
				$self->{host}->{undetermined}->{insufficientdata}->{totaltime} = substr($parsed->{element}[63][1],0,-1);

				$self->{host}->{undetermined}->{total}->{time} = $self->splitTime($parsed->{element}[66][1]);
				$self->{host}->{undetermined}->{total}->{totaltime} = substr($parsed->{element}[67][1],0,-1);
				
				
				$self->{host}->{all}->{total}->{time} = $self->splitTime($parsed->{element}[72][1]);
				$self->{host}->{all}->{total}->{totaltime} = substr($parsed->{element}[73][1],0,-1);
				$self->{host}->{all}->{total}->{knowntime} = substr($parsed->{element}[74][1],0,-1);
				
				
				# Host Log Entries
				my $logIndex = 0;
				my $logParserIndex = 75;
				
				# Search index for log entries
				while ($parsed->{element}[$logParserIndex][0] ne "logEntriesEven" && length($parsed->{element}[$logParserIndex][0]) != 0) {
					$logParserIndex++;
				}
				
				$logParserIndex--;

				while (length($parsed->{element}[$logParserIndex+1][1]) != 0) {
					$self->{host}->{logentries}->{event}->{$logIndex}->{starttime} = $parsed->{element}[++$logParserIndex][1];
					$self->{host}->{logentries}->{event}->{$logIndex}->{stoptime} = $parsed->{element}[++$logParserIndex][1];
					$self->{host}->{logentries}->{event}->{$logIndex}->{duration} = $self->splitTime($parsed->{element}[++$logParserIndex][1]);
					$self->{host}->{logentries}->{event}->{$logIndex}->{eventtext} = $parsed->{element}[++$logParserIndex][1];
					$self->{host}->{logentries}->{event}->{$logIndex}->{state} = $self->splitStateType($parsed->{element}[$logParserIndex][1]);
					$self->{host}->{logentries}->{event}->{$logIndex}->{stateinformation} = $parsed->{element}[++$logParserIndex][1];
					++$logIndex;
				}
			}
		} # End html host parsing
	# JSON parsing
	} elsif ($self->{parser}->{type} eq "JSON") {
		my $json = new JSON;
		my $jsonData = $json->decode($content);

		if (length($jsonData->{cgi_json_version}) == 0) {
			$self->{errMessage} = "No JSON content for parsing found! Icinga running?";
			return -1;
		} else {
			# For service availability
			if ($self->{report}->{type} eq "service") {
				my $logIndex = 0;
				foreach my $serviceData(@{$jsonData->{avail}->{service_availability}->{services}}){
					$self->{service}->{ok}->{unscheduled}->{time} = $self->calcTimeFromSeconds($serviceData->{time_ok_unscheduled});
					$self->{service}->{ok}->{unscheduled}->{totaltime} = $serviceData->{percent_time_ok_unscheduled};
					$self->{service}->{ok}->{unscheduled}->{knowntime} = $serviceData->{percent_known_time_ok_unscheduled};
	
					$self->{service}->{ok}->{scheduled}->{time} = $self->calcTimeFromSeconds($serviceData->{time_ok_scheduled});
					$self->{service}->{ok}->{scheduled}->{totaltime} = $serviceData->{percent_time_ok_scheduled};
					$self->{service}->{ok}->{scheduled}->{knowntime} = $serviceData->{percent_known_time_ok_scheduled};
					
					$self->{service}->{ok}->{total}->{time} = $self->calcTimeFromSeconds($serviceData->{total_time_ok});
					$self->{service}->{ok}->{total}->{totaltime} = $serviceData->{percent_total_time_ok};
					$self->{service}->{ok}->{total}->{knowntime} = $serviceData->{percent_known_time_ok};
					
					
					$self->{service}->{warning}->{unscheduled}->{time} = $self->calcTimeFromSeconds($serviceData->{time_warning_unscheduled});;
					$self->{service}->{warning}->{unscheduled}->{totaltime} = $serviceData->{percent_time_warning_unscheduled};
					$self->{service}->{warning}->{unscheduled}->{knowntime} = $serviceData->{percent_known_time_warning_unscheduled};
	
					$self->{service}->{warning}->{scheduled}->{time} = $self->calcTimeFromSeconds($serviceData->{time_warning_scheduled});
					$self->{service}->{warning}->{scheduled}->{totaltime} = $serviceData->{percent_time_warning_scheduled};
					$self->{service}->{warning}->{scheduled}->{knowntime} = $serviceData->{percent_known_time_warning_scheduled};
					
					$self->{service}->{warning}->{total}->{time} = $self->calcTimeFromSeconds($serviceData->{total_time_warning});
					$self->{service}->{warning}->{total}->{totaltime} = $serviceData->{percent_total_time_warning};
					$self->{service}->{warning}->{total}->{knowntime} = $serviceData->{percent_known_time_warning};
					
					
					$self->{service}->{unknown}->{unscheduled}->{time} = $self->calcTimeFromSeconds($serviceData->{time_unknown_unscheduled});;
					$self->{service}->{unknown}->{unscheduled}->{totaltime} = $serviceData->{percent_time_unknown_unscheduled};
					$self->{service}->{unknown}->{unscheduled}->{knowntime} = $serviceData->{percent_known_time_unknown_unscheduled};
	
					$self->{service}->{unknown}->{scheduled}->{time} = $self->calcTimeFromSeconds($serviceData->{time_unknown_scheduled});
					$self->{service}->{unknown}->{scheduled}->{totaltime} = $serviceData->{percent_time_unknown_scheduled};
					$self->{service}->{unknown}->{scheduled}->{knowntime} = $serviceData->{percent_known_time_unknown_scheduled};
					
					$self->{service}->{unknown}->{total}->{time} = $self->calcTimeFromSeconds($serviceData->{total_time_unknown});
					$self->{service}->{unknown}->{total}->{totaltime} = $serviceData->{percent_total_time_unknown};
					$self->{service}->{unknown}->{total}->{knowntime} = $serviceData->{percent_known_time_unknown};
					
	
					$self->{service}->{critical}->{unscheduled}->{time} = $self->calcTimeFromSeconds($serviceData->{time_critical_unscheduled});;
					$self->{service}->{critical}->{unscheduled}->{totaltime} = $serviceData->{percent_time_critical_unscheduled};
					$self->{service}->{critical}->{unscheduled}->{knowntime} = $serviceData->{percent_known_time_critical_unscheduled};
	
					$self->{service}->{critical}->{scheduled}->{time} = $self->calcTimeFromSeconds($serviceData->{time_critical_scheduled});
					$self->{service}->{critical}->{scheduled}->{totaltime} = $serviceData->{percent_time_critical_scheduled};
					$self->{service}->{critical}->{scheduled}->{knowntime} = $serviceData->{percent_known_time_critical_scheduled};
					
					$self->{service}->{critical}->{total}->{time} = $self->calcTimeFromSeconds($serviceData->{total_time_critical});
					$self->{service}->{critical}->{total}->{totaltime} = $serviceData->{percent_total_time_critical};
					$self->{service}->{critical}->{total}->{knowntime} = $serviceData->{percent_known_time_critical};
					
					
					$self->{service}->{undetermined}->{notrunning}->{time} = $self->calcTimeFromSeconds($serviceData->{time_undetermined_not_running});
					$self->{service}->{undetermined}->{notrunning}->{totaltime} = $serviceData->{percent_time_undetermined_not_running};
					
					$self->{service}->{undetermined}->{insufficientdata}->{time} = $self->calcTimeFromSeconds($serviceData->{time_undetermined_no_data});
					$self->{service}->{undetermined}->{insufficientdata}->{totaltime} = $serviceData->{percent_time_undetermined_no_data};
					
					$self->{service}->{undetermined}->{total}->{time} = $self->calcTimeFromSeconds($serviceData->{total_time_undetermined});
					$self->{service}->{undetermined}->{total}->{totaltime} = $serviceData->{percent_total_time_undetermined};
					
					
					$self->{service}->{all}->{total}->{time} = $self->calcTimeFromSeconds($serviceData->{total_time_all});
					$self->{service}->{all}->{total}->{totaltime} = $serviceData->{percent_total_time_all};
					$self->{service}->{all}->{total}->{knowntime} = $serviceData->{percent_known_time_all};
					
					
					foreach my $logEntriesData(@{$serviceData->{log_entries}}){
						$self->{service}->{logentries}->{event}->{$logIndex}->{starttime} = $logEntriesData->{start_time_string};
						$self->{service}->{logentries}->{event}->{$logIndex}->{stoptime} = $logEntriesData->{end_time_string};
						$self->{service}->{logentries}->{event}->{$logIndex}->{duration} = $self->splitTime($logEntriesData->{duration_string});
						$self->{service}->{logentries}->{event}->{$logIndex}->{eventtext} = $logEntriesData->{entry_type};
						$self->{service}->{logentries}->{event}->{$logIndex}->{state} = $self->splitStateType($logEntriesData->{entry_type});
						if ($self->{service}->{logentries}->{event}->{$logIndex}->{state}->{state} ne "downtime") {
							$self->{service}->{logentries}->{event}->{$logIndex}->{state}->{type} = lc($logEntriesData->{state_type});
							$self->{service}->{logentries}->{event}->{$logIndex}->{eventtext} = $logEntriesData->{entry_type}." (".$logEntriesData->{state_type}.")";
						}
						$self->{service}->{logentries}->{event}->{$logIndex}->{stateinformation} = $logEntriesData->{state_information};
						++$logIndex;
					}
				}
			} else {
				my $logIndex = 0;
				foreach my $hostData(@{$jsonData->{avail}->{host_availability}->{hosts}}){
					$self->{host}->{up}->{unscheduled}->{time} = $self->calcTimeFromSeconds($hostData->{time_up_unscheduled});;
					$self->{host}->{up}->{unscheduled}->{totaltime} = $hostData->{percent_time_up_unscheduled};
					$self->{host}->{up}->{unscheduled}->{knowntime} = $hostData->{percent_known_time_up_unscheduled};
					
					$self->{host}->{up}->{scheduled}->{time} = $self->calcTimeFromSeconds($hostData->{time_up_scheduled});
					$self->{host}->{up}->{scheduled}->{totaltime} = $hostData->{percent_time_up_scheduled};
					$self->{host}->{up}->{scheduled}->{knowntime} = $hostData->{percent_known_time_up_scheduled};
					
					$self->{host}->{up}->{total}->{time} = $self->calcTimeFromSeconds($hostData->{total_time_up});
					$self->{host}->{up}->{total}->{totaltime} = $hostData->{percent_total_time_up};
					$self->{host}->{up}->{total}->{knowntime} = $hostData->{percent_known_time_up};
					
					
					$self->{host}->{down}->{unscheduled}->{time} = $self->calcTimeFromSeconds($hostData->{time_down_unscheduled});;
					$self->{host}->{down}->{unscheduled}->{totaltime} = $hostData->{percent_time_down_unscheduled};
					$self->{host}->{down}->{unscheduled}->{knowntime} = $hostData->{percent_known_time_down_unscheduled};
					
					$self->{host}->{down}->{scheduled}->{time} = $self->calcTimeFromSeconds($hostData->{time_down_scheduled});
					$self->{host}->{down}->{scheduled}->{totaltime} = $hostData->{percent_time_down_scheduled};
					$self->{host}->{down}->{scheduled}->{knowntime} = $hostData->{percent_known_time_down_scheduled};
					
					$self->{host}->{down}->{total}->{time} = $self->calcTimeFromSeconds($hostData->{total_time_down});
					$self->{host}->{down}->{total}->{totaltime} = $hostData->{percent_total_time_down};
					$self->{host}->{down}->{total}->{knowntime} = $hostData->{percent_known_time_down};
					
					
					$self->{host}->{unreachable}->{unscheduled}->{time} = $self->calcTimeFromSeconds($hostData->{time_unreachable_unscheduled});;
					$self->{host}->{unreachable}->{unscheduled}->{totaltime} = $hostData->{percent_time_unreachable_unscheduled};
					$self->{host}->{unreachable}->{unscheduled}->{knowntime} = $hostData->{percent_known_time_unreachable_unscheduled};
					
					$self->{host}->{unreachable}->{scheduled}->{time} = $self->calcTimeFromSeconds($hostData->{time_unreachable_scheduled});
					$self->{host}->{unreachable}->{scheduled}->{totaltime} = $hostData->{percent_time_unreachable_scheduled};
					$self->{host}->{unreachable}->{scheduled}->{knowntime} = $hostData->{percent_known_time_unreachable_scheduled};
					
					$self->{host}->{unreachable}->{total}->{time} = $self->calcTimeFromSeconds($hostData->{total_time_unreachable});
					$self->{host}->{unreachable}->{total}->{totaltime} = $hostData->{percent_total_time_unreachable};
					$self->{host}->{unreachable}->{total}->{knowntime} = $hostData->{percent_known_time_unreachable};
					
					
					$self->{host}->{undetermined}->{notrunning}->{time} = $self->calcTimeFromSeconds($hostData->{time_undetermined_not_running});
					$self->{host}->{undetermined}->{notrunning}->{totaltime} = $hostData->{percent_time_undetermined_not_running};
					
					$self->{host}->{undetermined}->{insufficientdata}->{time} = $self->calcTimeFromSeconds($hostData->{time_undetermined_no_data});
					$self->{host}->{undetermined}->{insufficientdata}->{totaltime} = $hostData->{percent_time_undetermined_no_data};
					
					$self->{host}->{undetermined}->{total}->{time} = $self->calcTimeFromSeconds($hostData->{total_time_undetermined});
					$self->{host}->{undetermined}->{total}->{totaltime} = $hostData->{percent_total_time_undetermined};
					
					
					$self->{host}->{all}->{total}->{time} = $self->calcTimeFromSeconds($hostData->{total_time_all});
					$self->{host}->{all}->{total}->{totaltime} = $hostData->{percent_total_time_all};
					$self->{host}->{all}->{total}->{knowntime} = $hostData->{percent_known_time_all};


					foreach my $logEntriesData(@{$hostData->{log_entries}}){
						$self->{host}->{logentries}->{event}->{$logIndex}->{starttime} = $logEntriesData->{start_time_string};
						$self->{host}->{logentries}->{event}->{$logIndex}->{stoptime} = $logEntriesData->{end_time_string};
						$self->{host}->{logentries}->{event}->{$logIndex}->{duration} = $self->splitTime($logEntriesData->{duration_string});
						$self->{host}->{logentries}->{event}->{$logIndex}->{eventtext} = $logEntriesData->{entry_type};
						$self->{host}->{logentries}->{event}->{$logIndex}->{state} = $self->splitStateType($logEntriesData->{entry_type});
						if ($self->{host}->{logentries}->{event}->{$logIndex}->{state}->{state} ne "downtime") {
							$self->{host}->{logentries}->{event}->{$logIndex}->{state}->{type} = lc($logEntriesData->{state_type});
							$self->{host}->{logentries}->{event}->{$logIndex}->{eventtext} = $logEntriesData->{entry_type}." (".$logEntriesData->{state_type}.")";
						}
						$self->{host}->{logentries}->{event}->{$logIndex}->{stateinformation} = $logEntriesData->{state_information};
						++$logIndex;
					}
				}
			}

			return 0;
		}
	}
}


# Internal method for parseContent()
# Start handler for html parser 
sub startHandler {
	return if (shift ne 'td');
	my ($class) = shift->{class};
	my $self = shift;
	my $text;
	
	$self->handler(text => sub{$text = shift;},"dtext");
	$self->handler(end => sub{push (@{$self->{element}},[$class,$text]) if (shift eq 'td')},"tagname");
	
	return $self;
}


# Internal method for parseContent()
# Split time and delete unit 
sub splitTime {
	my $self = shift;
	my $values = shift;
	my $value = {};
	
	my @tmpValues = split(/ /,$values);
	
	$value->{days} = substr(@tmpValues[0],0,-1);
	$value->{hours} = substr(@tmpValues[1],0,-1);
	$value->{minutes} = substr(@tmpValues[2],0,-1);
	my @tmpSeconds = split(/s/,@tmpValues[3]);
	$value->{seconds} = @tmpSeconds[0];
	
	return $value;
}


# Internal method for parseContent()
# Calculate time from seconds to days, hours, minutes and seconds
sub calcTimeFromSeconds {
	my $self = shift;
	my $values = shift;
	my $value = shift;
	my $tmpModulo;
	
	my $moduloHours = $values % 86400;
	$value->{days} = ($values - $moduloHours) / 86400;
	
	my $moduloMinutes = $moduloHours % 3600;
	$value->{hours} = ($moduloHours - $moduloMinutes) / 3600;
	
	my $moduloSeconds = $moduloMinutes % 60;
	$value->{minutes} = ($moduloMinutes - $moduloSeconds) / 60;
	
	$value->{seconds} = $moduloSeconds;
	
	return $value;
}


# Internal method for parseContent()
# Split state type in state and state type
sub splitStateType {
	my $self = shift;
	my $stateTypes = shift;
	
	my $state = {};
	
	my @tmpStateType = split(/ /,$stateTypes);
	
	$state->{objecttype} = lc(@tmpStateType[0]);
	$state->{state} = lc(@tmpStateType[1]);
	$state->{type} = lc(substr(@tmpStateType[2],1,-1));
	
	if ((@tmpStateType[2] eq "(HARD)") || (@tmpStateType[2] eq "(SOFT)")) {
		$state->{type} = lc(substr(@tmpStateType[2],1,-1));
	} else {
		$state->{type} = lc(@tmpStateType[2]);
	}

	return $state;
}

=pod

=over

=item getParsedBreakdownValue()

Returns values from parsed html content.

=back

=over

B<List of parameters:>

 There are 3 parts of parameters: state, type and time

=over

B<List of states:>

 * ok
 * warning
 * critical
 * unknown
 * all
 * up
 * down
 * unreachable


B<For all states can use the follow types:>

 * unscheduled
 * scheduled
 * total

B<For the types can use follow times:>

 * totaltime (in %)
 * knowntime (in %)
 * time
 
=over

B<For the time can use follow parameters:>

 * days
 * hours
 * minutes
 * seconds

=back

B<For the state I<undetermined> can use follow types:>

 * notrunning
 * insufficientdata
 * total

B<And for this types can use follow times:>

 * totaltime
 * time
 
=over

B<For the time can use follow parameters:>

 * days
 * hours
 * minutes
 * seconds

=back

=back

=back

=head2 EXAMPLE

 $Avail->getParsedBreakdownValue("ok","scheduled","knowntime")
 
 or
 
 $Avail->getParsedBreakdownValue("ok","scheduled","time","days")

=cut
sub getParsedBreakdownValue {
	my $self = shift;
	
	my ($state, $type, $time, $parameter) = @_;
	my $ReportType = $self->getReportType();

	# Check state
	if ($state eq "ok" || $state eq "warning" || $state eq "critical" || $state eq "unknown" || $state eq "all" || $state eq "up"|| $state eq "down" || $state eq "unreachable") {
		# Check type
		if ($type eq "unscheduled" || $type eq "scheduled" || $type eq "total") {
			# Check time
			if ($time eq "totaltime" || $time eq "knowntime") {
				return $self->{$ReportType}->{$state}->{$type}->{$time};
			} elsif ($time eq "time") {
				# Check parameter
				if ($parameter eq "days" || $parameter eq "hours" || $parameter eq "minutes" || $parameter eq "seconds") {
					return $self->{$ReportType}->{$state}->{$type}->{$time}->{$parameter};
				} else {
					$self->{errMessage} = "getParsedValue(): ".$parameter." is not a defined parameter!";
					return -1;
				}
			} else {
				$self->{errMessage} = "getParsedValue(): ".$time." is not a defined time!";
				return -1;
			}
		} else {
			$self->{errMessage} = "getParsedValue(): ".$type." is not a defined type!";
			return -1;
		}
	# Check state
	} elsif ($state eq "undetermined") {
		# Check type
		if ($type eq "notrunning" || $type eq "insufficientdata" || $type eq "total") {
			# Check time
			if ($time eq "totaltime") {
				return $self->{$ReportType}->{$state}->{$type}->{$time};
			} elsif ($time eq "time") {
				# Check parameter
				if ($parameter eq "days" || $parameter eq "hours" || $parameter eq "minutes" || $parameter eq "seconds") {
					return $self->{$ReportType}->{$state}->{$type}->{$time}->{$parameter};
				} else {
					$self->{errMessage} = "getParsedValue(): ".$parameter." is not a defined parameter!";
					return -1;
				}
			} else {
				$self->{errMessage} = "getParsedValue(): ".$time." is not a defined time!";
				return -1;
			}
		} else {
			$self->{errMessage} = "getParsedValue(): ".$type." is not a defined type!";
			return -1;
		}
		
	} else {
		$self->{errMessage} = "getParsedValue(): ".$state." is not a defined state!";
		return -1;
	}
}



=pod

=over

=item getParsedEventLogEntries()

Returns all parsed event log entries

=back

=head2 EXAMPLE

  $Avail->getParsedEventLogEntries()

=cut
sub getParsedEventLogEntries {
	my $self = shift;
	my $ReportType = $self->getReportType();
	
	return $self->{$ReportType}->{logentries}->{event};	
}


=pod

=over

=item getErrorMessage()

Returns error message from object

=back

=head2 EXAMPLE

  $Avail->getErrorMessage

=cut
sub getErrorMessage {
	my $self = shift;
	
	return $self->{errMessage};	
}


1;

=head1 REQUIRES

Perl 5, strict, Switch, HTML::Parser, JSON, JSON::XS

=head1 AUTHOR

Michael Luebben <michael_luebben@web.de>

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
