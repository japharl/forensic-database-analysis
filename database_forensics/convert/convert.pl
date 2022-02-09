use strict;
use Config::Tiny;
use Encode;
use DBI;
use Encode::Guess qw/cp1251 ascii/;
my $Config=Config::Tiny->read("config.ini");

my $db = $Config->{Settings}->{database};
my $host = $Config->{Settings}->{host};
my $newhost = $Config->{Settings}->{newhost};
my $port = $Config->{Settings}->{port};
my $user = $Config->{Settings}->{user};
my $password = $Config->{Settings}->{password};
my $new_db_name = $Config->{Settings}->{newname};

my $dbh = DBI->connect("DBI:mysql:database=$db;host=$host",$user,$password,{mysql_auto_reconnect=>1}) or die "$!";
$dbh->{mysql_enable_utf8}=1;
$dbh->do("set names utf8");
#$dbh->do("set names cp1251");

print "Connected...(1:2)\n";
my $dbhtemp = DBI->connect("DBI:mysql:database=test;host=$newhost;port=$port",$user,$password,{mysql_auto_reconnect=>1}) or die "$!";
print "Connected....(2:2)\n";
print "Newhost : $newhost\nNew database name: $new_db_name\n";
print "Dropping database...\n";
$dbhtemp->do("drop database if exists " . $new_db_name . ";");
print "Creating database...\n";
$dbhtemp->do("create database " . $new_db_name . ";");
print "Connecting: (3:2)\n";
my $dbh2 = DBI->connect("DBI:mysql:database=" . $new_db_name . ";host=$newhost;port=$port",$user,$password,{mysql_auto_reconnect=>1}) or die "$!";
$dbh2->{mysql_enable_utf8}=1;
$dbh2->do("SET NAMES utf8");

# 1 find all tables...
my $sql=qq{show tables};
my $sth = $dbh->prepare($sql);
$sth->execute();

my $table ; #  = 'moderatorlog';

$sth->bind_columns(undef,\$table);
while ($sth->fetch()){
  #next if (!($table eq 'forum'));
  print "Processing Table: $table\n";
  my $sql2="desc " . $table ;
  my $sth2= $dbh->prepare($sql2);
  $sth2->execute();

  my $field;
  my $type;
  my $null;
  my $key;
  my $default;
  my $extra;
  $sth2->bind_columns(undef,\$field,\$type,\$null,\$key,\$default,\$extra);

  my $create_str = "CREATE TABLE " . $table . " (";
  my @e;
  my @t;
  while ($sth2->fetch()){
    push @e,$field;
    if ($type =~/CHAR/i){
      if ($type =~/varchar/i){
        my @x = split /\(/,$type;
        my @z = split /\)/,$x[1];
        my $a = $z[0] . '';
        my $b = $z[0] * 4;
        $type =~ s/$a/$b/g;
      } else {
        my @x = split /\(/,$type;
        my @z = split /\)/,$x[1];
        my $a = $z[0] . '';
        $type =~ s/$a/255/g;
      }
    }
    push @t,$type; 
  }

  my $e = @e;

  my $i = 1;
  my $str = '';
  foreach my $el(@e){
   if ($i == $e){
     $str = $str . " " . $el ;
     $create_str = $create_str . "$el " . $t[$i-1] . " ";
   }  else {
     $create_str = $create_str . "$el " . $t[$i-1] . ", ";
     $str = $str . " " . $el . ",";
   }
   $i=$i+1;
  }
  
  $create_str = $create_str . ") ENGINE=MyISAM;";
  $dbh2->do($create_str);

  my $sqlzz="show index from " . $table ;
  my $sthzz=$dbh->prepare($sqlzz);
  $sthzz->execute();

  my $tablex;
  my $nonunique;
  my $keyname;
  my $seq_in_index;
  my $colname;
  my $collation;
  my $card;
  my $sub;
  my $packed;
  my $null;
  my $index_type;
  my $comment;
  my $index_comment;
  
  #$sthzz->bind_columns(undef,\$tablex,\$nonunique,\$keyname,\$seq_in_index,\$colname,\$collation,\$card,\$sub,\$packed,\$null,\$index_type,\$comment); # IF ON AN OLDER MYSQL VERSION
  $sthzz->bind_columns(undef,\$tablex,\$nonunique,\$keyname,\$seq_in_index,\$colname,\$collation,\$card,\$sub,\$packed,\$null,\$index_type,\$comment,\$index_comment);

  my %columns;

  my $lastsql;
  while ($sthzz->fetch()){
    if (exists $columns{$keyname}){
      $columns{$keyname} = $columns{$keyname} . "," . $colname;
    } else {
      $columns{$keyname} = $colname ;
    }
  }

  foreach my $k (keys %columns){
    my $iname = $k;
    if ($k eq 'PRIMARY'){
      $iname = 'PRIMARY_X';
    }
    my $sqla= "CREATE INDEX " . $iname . " ON " . $table . " ( " . $columns{$k} . ")";
    $dbh2->do($sqla);
  }

  my $sql3= "SELECT " . $str . " FROM " . $table;
  my $sth3 = $dbh->prepare($sql3);
  $sth3->execute();


  while (my @ary = $sth3->fetchrow_array()){
    my $insert_str;
    $insert_str = "INSERT INTO " . $table . " (" . $str . ") VALUES (";
    my $count = @ary;
    my $i=1;
    my @bind;
    my @values;
    foreach my $em (@ary){
      if ($t[$i-1]=~/blob/){
      } else {
      $em = myCheckEncode($em);
      }
      if ($count == $i){
        push @bind,'?';
        push @values , $em;
      } else {
        push @bind,'?,';
        push @values , $em;
      }
      $i=$i+1;
    }
    foreach my $b (@bind){
      $insert_str = $insert_str . $b;
    }
    $insert_str = $insert_str . ");";
   
    my $sth3 = $dbh2->prepare(qq($insert_str)); 
    $sth3->execute(@values);
  }

}

print "*** Done. ***\n";

sub myCheckEncode{
  my $val = shift;
  my $str = $val;
  eval{
    $str = decode("cp1251",$str);
  };
  if ($@){
    return($val);
  }
  return($str);
}

__END__

=head1 NAME convert.pl

This process allows you to convert a database in (some character set) to another database in utf8 format.  You probably will need to comment or uncomment lines in myCheckEncode, possibly the select statement, and the initial utf8 statements at the start of the dbh declaration files.

Note: Assumes test database is connectable via user root.

=head2 Legal

©2022 The MITRE Corporation. All Rights Reserved. 

Approved for Public Release; Distribution Unlimited. Public Release Case Number 21-1212
NOTICE - This (software/technical data) was produced for the U. S. Government under Contract Number 70RSAT20D00000001, and is subject to Federal Acquisition Regulation Clause 52.227-14, Rights in Data—General. As prescribed in 27.409(b)(1), insert the following clause with any appropriate alternates:
52.227-14 Rights in Data -- General (May 2014) – Alternate II (Dec 2007) and Alternate III (Dec 2007) (DEVIATION)
No other use other than that granted to the U. S. Government, or to those acting on behalf of the U. S. Government under that Clause is authorized without the express written permission of The MITRE Corporation.
For further information, please contact The MITRE Corporation, Contracts Management Office, 7515 Colshire Drive, McLean, VA 22102-7539, (703) 983-6000.

=cut
