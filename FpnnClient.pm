package FpnnClient;
use FpnnHeader;
use FpnnQuest;
use Data::MessagePack;
use IO::Socket;
use Crypt::PK::ECC;
use Crypt::Mode::CFB;
use Digest::MD5 qw(md5);
use Digest::SHA qw(sha256);

sub new {
    my ($class, $ip, $port, $timeout) = @_;
    my $self = {};
    
    $self->{"ip"} = $ip;
    $self->{"port"} = $port;
    $self->{"timeout"} = $timeout || 5000;

	bless $self, $class;
	return $self;
}

sub encrypt {
    my ($self, $buffer, $isEncrypt) = @_;
    my $cipher = Crypt::Mode::CFB->new('AES');
    if ($isEncrypt) {
        return $cipher->encrypt($buffer, $self->{"key"}, $self->{"iv"});
    } else {
        return $cipher->decrypt($buffer, $self->{"key"}, $self->{"iv"});
    }
}

sub enableEncryptor {
    my ($self, $peerPubFile, $curveName, $strength) = @_;
    $curveName = $curveName || "secp256k1";
    $strength = $strength || 128;

    if (not $curveName ~~ ["secp256k1", "secp256r1", "secp192r1", "secp224r1"]) {
        $curveName = "secp256k1";
    }
    if (not $strength ~~ [128, 256]) {
        $strength = 128;
    }
    $self->{"strength"} = $strength;
    
    my $peerPubKey = Crypt::PK::ECC->new($peerPubFile);
    
    my $ec = Crypt::PK::ECC->new();
    $ec->generate_key($curveName);

    my $pubKey = substr($ec->export_key_raw('public'), 1);
    
    my $secret = $ec->shared_secret($peerPubKey);

    $self->{"iv"} = md5($secret); 
    if ($strength == 128) {
        $self->{"key"} = substr($secret, 0, 16);
    } else {
        if (length($secret) == 32) {
            $self->{"key"} = $secret;
        } else {
            $self->{"key"} = sha256($secret);    
        }
    }
    $self->{"isEncryptor"} = 1;
    $self->{"canEncryptor"} = 0;
    
    $an = $self->sendQuest("*key", {"publicKey" => $pubKey, "streamMode" => 0, "bits" => $self->{"strength"}});
}

sub reconnectServer {
    my $self = shift();
	my $timeout = $self->{"timeout"} / 1000;
    
	$self->{"socket"} = IO::Socket::INET->new(
        PeerHost => $self->{"ip"},
        Proto => "tcp",
        PeerPort => $self->{"port"},
        Timeout => $timeout 
    );
}

sub sendQuest {
	my ($self, $method, $params, $oneway) = @_;
	$oneway = $oneway || 0;
	my $quest = FpnnQuest->new($method, $params, $oneway);
	
    if (not defined $self->{"socket"}) {
		$self->reconnectServer();
	}
	
    my $buffer = $quest->raw();
	
    if ($self->{"isEncryptor"} && $method ne "*key") {
		$buffer = pack("VA*", length($buffer), $self->encrypt($buffer, 1));
	}
	
    $self->{"socket"}->send($buffer);
	
    if ($oneway) {
		return;
	}
	
    $self->{"canEncryptor"} = 0;	
    
    my @arr;
	if ($self->{"isEncryptor"}) {
		$self->{"socket"}->recv($recvBuffer, 4);
		@arr = unpack("V", $recvBuffer);
		$self->{"socket"}->recv($recvBuffer, $arr[0]);
		$recvBuffer = $self->encrypt($recvBuffer, 0);
        @arr = unpack("A4CCCCVVA*", $recvBuffer);
	} else {
		$self->{"socket"}->recv($recvBuffer, 16);
		@arr = unpack("A4CCCCVV", $recvBuffer);
	}
    
    if ($arr[6] ne $quest->getSeqNum()) {
		warn("Server returned unmatched seqNum, quest seqNum: " . $quest->getSeqNum() . " server returned seqNum:" . $arr[6]);
		return;
	}
	
	my $payload = "";
	if ($self->{"isEncryptor"}) {
		$payload = $arr[7];
	} else {
		$self->{"socket"}->recv($payload, $arr[5]);
	}

	my $anwser = Data::MessagePack->unpack($payload);
	return $anwser;
}

1;
