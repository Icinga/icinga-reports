package Configuration;

use strict;


=pod

=head1 NAME

Configuration.pm

=head1 Version

Version 0.0.2

=head1 DESCRIPTION

Read a configuration file in.

=head1 SYNOPSIS

  use Configuration;
  
  $Config = new Configuration;
  $result = $Config-getParsedValue(<parameter>);

=head1 EXAMPLE

=over

B<Configuration file I<default.ini> contains:>

  # ===== Database Authentification =====
  DBHOST = localhost
  DBNAME = test
  DBUSER = username
  DBPASS = password

=back
 
 
  use Configuration;
  
  $Config = new Configuration("default.ini") 
  $dbHost = $Config-getParsedValue("DBHOST");

=head1 METHODS

=cut

# Constructor
sub new {
	my $pkg = shift;
	my $self = {};
	$self->{configFileName} = shift;

	bless $self, $pkg;
	
	# Read configuration file
	$self->readConfigFile;
	
	return $self;
}


# Internal method for the constructor
# Read configuration file
sub readConfigFile {
	my $self = shift;

	open(CONFIGFILE, "<$self->{configFileName}") || die "Config file etc/".$self->{configFileName}." not found!\n";
		while (<CONFIGFILE>) {
		    chomp;                  # no newline
		    s/#.*//;                # no comments
		    s/^\s+//;               # no leading white
		    s/\s+$//;               # no trailing white
		    next unless length;     # anything left?
		    my ($var, $value) = split(/\s*=\s*/, $_, 2);
		    $self->{config}->{$var} = $value;
		}
	close(CONFIGFILE);

	return 0;
}


=pod

=over

=item getParsedValue()

Returns a value from configuration file

=back

=head2 EXAMPLE

  $Config->getParsedValue("DBHOST")

=cut
sub getParameter {
	my $self = shift;
	my ($parameter) = @_;
	
	my $result = $parameter." is not a defined parameter!";
	
	if (length($self->{config}->{$parameter}) != 0) {
		$result = $self->{config}->{$parameter};
	} else {	
		if ($self->{config}->{$parameter} == "TABLEPREFIX") {
			$result = $self->{config}->{$parameter} = "";
		}
	}
	
	return $result
}


1;

=head1 REQUIRES

Perl 5, strict

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
