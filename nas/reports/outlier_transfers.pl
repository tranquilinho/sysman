#!/usr/bin/perl -w
# Define the std dev statistical function in SQLlite and apply it to find modules with highly variable transfer patterns

use DBI;
# use strict;

# Aggregate functions require a package
package stddev_agg; 

sub new { bless [], shift; } 
sub step { 
    my ( $self, $value ) = @_; 
    push @$self, $value; 
} 
sub finalize { 
    my $self = $_[0]; 
    return stddev($self); 
#     return mean($self); 
}

my $db="backup_log.db";

# returns the standard deviation of a list 
sub stddev { 
    my $ar = shift; 
    return 0 unless defined $ar && @$ar > 1; 
    my ($mean, $sum_sqr) = (mean($ar), 0); 
    for (@$ar) { 
      $sum_sqr += ($mean - $_)*($mean - $_) 
    } 
    return sqrt($sum_sqr / (@$ar - 1)); 
} 
# returns the mean of a list 
sub mean { 
    my $ar = shift; 
    my $sum = 0; 
    $sum += $_ for @$ar; 
    return @$ar > 0 ? $sum / @$ar : 0; 
}

my $dbh = DBI->connect("dbi:SQLite:$db", "", "", {RaiseError => 1, AutoCommit => 1}) or die "connecting: $DBI::errstr";

# Parameters: name within SQLLite, number of arguments, function handle, operation type
$dbh->func("stddev", 1, stddev_agg, "create_aggregate"); 

# my $sql = " SELECT module,stddev(size/1048576) FROM backup group by module"; 
my $sql = "select module, round(stddev(size/1048576)) as stdev from backup where julianday('now') - julianday(date) < 7 group by module order by stdev desc limit 10";

my $all = $dbh->selectall_arrayref($sql);

foreach my $row (@$all) {
	my ($module, $size) = @$row;
	print "$module|$size\n";
}
# my @r = $dbh->selectrow_array($sql);
# print join "\t", @r, "\n";
# $dbh ->close()
