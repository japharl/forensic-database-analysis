use Encode qw/from_to/;

my $IN;
my $OUT;

my $encoding = shift;

open($IN,"<","note.txt");
open($OUT,">","$encoding.txt");

while (<$IN>){
  my $line = $_;
  $line =~ chomp($line);
  from_to($line,"utf8","$encoding");
  print $OUT $line ;
}
close $OUT;
close $IN;

__END__

=head2 legal

Approved for Public Release; Distribution Unlimited. Public Release Case Number 21-1212

©2022 The MITRE Corporation. All Rights Reserved. 

NOTICE
This (software/technical data) was produced for the U. S. Government under Contract Number 70RSAT20D00000001, and is subject to Federal Acquisition Regulation Clause 52.227-14, Rights in Data—General. As prescribed in 27.409(b)(1), insert the following clause with any appropriate alternates:
52.227-14 Rights in Data -- General (May 2014) – Alternate II (Dec 2007) and Alternate III (Dec 2007) (DEVIATION)
No other use other than that granted to the U. S. Government, or to those acting on behalf of the U. S. Government under that Clause is authorized without the express written permission of The MITRE Corporation.
For further information, please contact The MITRE Corporation, Contracts Management Office, 7515 Colshire Drive, McLean, VA 22102-7539, (703) 983-6000.

=cut
