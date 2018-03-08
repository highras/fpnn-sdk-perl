package FpnnQuest;
use feature 'state';
use FpnnHeader;
use Time::HiRes qw(time);

our $FPNN_PERL_VERSION = 1;
our $FPNN_FLAG_MSGPACK = 0x80;
our $FPNN_MT_ONEWAY = 0;
our $FPNN_MT_TWOWAY = 1;
our $FPNN_MT_ANSWER = 2;

sub new {
    my ($class, $method, $params, $oneway) = @_;
    my $self = {};

    $oneway = $oneway || 0;
    
    $self->{"header"} = FpnnHeader->new("FPNN",$FPNN_PERL_VERSION, 0, 0, 0, 0);
    $self->{"header"}->setMtype($oneway ? $FPNN_MT_ONEWAY : $FPNN_MT_TWOWAY);
    $self->{"header"}->setSs(length($method));
    if (not $oneway) {
        $self->{"seqNum"} = nextSeqNum();
    }
	$self->{"method"} = $method;
	$self->{"header"}->setFlag($FPNN_FLAG_MSGPACK);
    use Data::MessagePack;
    my $mp = Data::MessagePack->new();
    $mp->utf8(1);
    $self->{"payload"} = $mp->pack($params);
	$self->{"header"}->setPsize(length($self->{"payload"}));
	$self->{"cTime"} = int(time * 1000);

	bless $self, $class;
	return $self;
}

sub nextSeqNum {
	state $nextSeq = 0;
	if ($nextSeq >= 2147483647) {
		$nextSeq = 0;
	}
	$nextSeq += 1;
	return $nextSeq;
}

sub getSeqNum {
    my $self = shift();
    return $self->{"seqNum"};
}

sub raw {
	my $self = shift();
	$packet = $self->{"header"}->packHeader();
	if ($self->{"header"}->getMtype() == $FPNN_MT_TWOWAY) {
		$packet .= pack("V", $self->{"seqNum"}); 
	}
	$packet .= pack("A*A*", $self->{"method"}, $self->{"payload"});
	return $packet;
}

1;
