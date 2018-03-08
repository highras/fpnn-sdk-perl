package FpnnHeader;

sub new {
    my $class = shift();
    my $self = {};
	$self->{"magic"} = shift();
	$self->{"version"} = shift();
	$self->{"flag"} = shift();
	$self->{"mtype"} = shift();
	$self->{"ss"} = shift();
	$self->{"psize"} = shift();
    
	bless $self, $class;
    return $self;
}

sub setMtype {
    my ($self, $mtype) = @_;
    $self->{"mtype"} = $mtype;
}

sub getMtype {
    my $self = shift();
    return $self->{"mtype"};
}

sub setSs {
    my ($self, $ss) = @_;
    $self->{"ss"} = $ss;
}

sub setFlag {
    my ($self, $flag) = @_;
    $self->{"flag"} = $flag;
}

sub setPsize {
    my ($self, $psize) = @_;
    $self->{"psize"} = $psize;
}

sub packHeader {
    my ($self) = @_;
    return pack("A*CCCCV", $self->{"magic"}, $self->{"version"}, $self->{"flag"}, $self->{"mtype"}, $self->{"ss"}, $self->{"psize"});
}

1;
