package FingerPrint::Query;

use  lib './';
#use Moose;
use WWW::Mechanize ();
use HTML::TreeBuilder 5 -weak;
use HTML::TreeBuilder::XPath;
#use namespace::clean;
use Spreadsheet::ParseExcel::Simple;
use Spreadsheet::WriteExcel;
use Data::Printer;
#use utf8::all;
use Encode qw (encode decode);
use Text::CSV_XS qw(csv);

my $PARAMS = {
    ua => 'Windows IE 6',
    index => 'http://192.168.73.12:7001/finger',
    url => 'http://192.168.73.12:7001/finger/jsp/checksearch.do?meth=checkSearchBh&id=sbbh&sbbh=',
    login =>{
        form => ['form_id','loginform'],
        user => ['userid' , '4199003314'],
        pwd => ['password', '1DF0E2280F9BA141'],
    },
    fmt => [
        ['name' ,'status' ],
        [ '//table[@class="tableBorder"]//tr[2]/td[3]/text()', '//table[@class="tableBorder"]//tr[2]/td[5]/text()'],
    ],
};
#my $mode = "single";
my $mech = WWW::Mechanize->new;


#print @$fields,"\n";
sub new {
    my $class = shift;
    my ($mode,$source) = @_;
    my $self = {
        _mode => $mode,
        _source => $source
    };

    $mech->agent_alias($PARAMS->{ua});
    $mech->get($PARAMS->{index});
    $mech->submit_form(
        $PARAMS->{login}->{form}->[0] => $PARAMS->{login}->{form}->[1],
        fields => {
        $PARAMS->{login}->{user}->[0] => $PARAMS->{login}->{user}->[1],
        $PARAMS->{login}->{pwd}->[0] => $PARAMS->{login}->{pwd}->[1],
        },

    );
    $mech->success or die "******Login failed!!!******";

    bless $self, $class;
    return $self;
}


sub query_by_sinum {
    my $self = shift;
    my $sinum = shift;
    my $url = $PARAMS->{url};
    $url .= $sinum;
    my $result = $mech->get($url) or die "You do not have the result!!";
    my $content = $result->content;
    my $tree = HTML::TreeBuilder::XPath->new_from_content($content);
    my $row = [];
    #my $ar = [];

my $values = ${$PARAMS->{fmt}}[1];

foreach my $v (@$values) {
    #my $field = $fields->[$i];
    my $value = $tree->findvalue($v);
    $value =~ s/\s//g ;
    #p $value;
    push @$row, $value;
}


=pod
    foreach my $it   (@{$PARAMS->{fmt}}) {
        my $field = $it->[0];
        my $value = $tree->findvalue($it->[1]);
        push @$row , {$field => $value};

    }
=cut
    $tree->delete;
    #p $row;
    return $row;

}

sub get_sinums_from_xls {
    my $self = shift;
    my $mode = $self->{_mode};
    my $source = $self->{_source};
    if ($mode eq 's' ) {
        warn "===You should use query_by_sinum method!===";
        return;
    }
    my $xls = Spreadsheet::ParseExcel::Simple->read($source) or die "******You've got wrong file!!******";
    my @a = ();
    foreach my $sheet ($xls->sheets) {
        while ($sheet->has_data) {
           my @data = $sheet->next_row;
           #p @data;
           push @a , $data[0];
        }
    }
    #p @a;
    return @a;
}

sub _query {
    my $self = shift;
    my $mode = $self->{_mode};
    my $source = $self->{_source};
    my $title = ${$PARAMS->{fmt}}[0];
    # p $title;
    if ($mode eq 's') {
        my $r = [];
        push @$r, $title;
        push @$r, $self->query_by_sinum($source);
        #p $r;
        return $r;

    }
    if ($mode eq 'f') {
        my $r = [];
        my @a = $self->get_sinums_from_xls($source) ;
        #p @a;
        foreach $n (@a) {
            #p $n;
            #my $str = $n+""
            #p $self->query_by_sinum($n);
            push @$r , $self->query_by_sinum($n);
        }
        unshift @$r, $title;
        #p $r;
        return $r;
    }

}

sub out_csv {
    my $self = shift;
    my $csv_file = shift or die "******You should give the csv filename!******";

    #p $csv_file;
    #p $self->_query;
    my $query = $self->_query();
    csv (in => $query, out => $csv_file, sep_char=> ",") or die "******Failed output csv!******";
}

sub out_xls {
    my $self = shift;
    my $xls_file = shift or die "******You should give the file name!******";
    my $workbook = Spreadsheet::WriteExcel->new($xls_file) or die "******Can not create xls file!******";
    $workbook->set_codepage(1); # ANSI, MS Windows
    my $worksheet = $workbook->add_worksheet();
    my $col = $row = 0;
    my $ar = [];
    foreach my $q (@{$self->_query}){
    my @arr_ = map  decode("gbk",$_), @$q;
    push @$ar, \@arr_;
    };
    #p $res;
    $worksheet->write_col(0, 0, $ar); #or die "******Can not yield new xls data!******";
    $workbook->close();

}

sub DESTROY {
    print "\n\nTings have already done.";
}


#no Moose;
1;
