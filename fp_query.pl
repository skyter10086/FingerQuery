use lib './';
use FingerPrint::Query;
use Getopt::Long;
use Data::Printer;

my $data   = "41000040844132";
my $mode = 's';
my $out = 'output.csv';
GetOptions ("mode=s" => \$mode,    # numeric
            "source=s"   => \$data,      # string
            "out=s"  => \$out)   # flag
or die("Error in command line arguments\n");
die "You shoude give the mode param 's' or 'f' " unless ($mode eq 's' || $mode eq 'f');
#p $data;
#p $mode;
my $fpq = FingerPrint::Query->new($mode, $data);
#p $fpq;
if ($out =~ /^.*\.csv$/) {
    $fpq->out_csv($out);
} elsif ($out =~ /^.*\.xls$/) {
    $fpq->out_xls($out);        
} else {
    die "You should give .xls or .csv with post-fix!";
}
