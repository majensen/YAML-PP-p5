# ABSTRACT: Construct data structure from Parser Events
use strict;
use warnings;
package YAML::PP::Constructor;

our $VERSION = '0.000'; # VERSION

use YAML::PP;

use constant DEBUG => ($ENV{YAML_PP_LOAD_DEBUG} or $ENV{YAML_PP_LOAD_TRACE}) ? 1 : 0;
use constant TRACE => $ENV{YAML_PP_LOAD_TRACE} ? 1 : 0;

my %cyclic_refs = qw/ allow 1 ignore 1 warn 1 fatal 1 /;

sub new {
    my ($class, %args) = @_;

    my $cyclic_refs = delete $args{cyclic_refs} || 'allow';
    die "Invalid value for cyclic_refs: $cyclic_refs"
        unless $cyclic_refs{ $cyclic_refs };
    my $schema = delete $args{schema};

    if (keys %args) {
        die "Unexpected arguments: " . join ', ', sort keys %args;
    }

    my $self = bless {
        schema => $schema,
        cyclic_refs => $cyclic_refs,
    }, $class;
}

sub init {
    my ($self) = @_;
    $self->set_docs([]);
    $self->set_stack([]);
    $self->set_anchors({});
}

sub docs { return $_[0]->{docs} }
sub stack { return $_[0]->{stack} }
sub anchors { return $_[0]->{anchors} }
sub set_docs { $_[0]->{docs} = $_[1] }
sub set_stack { $_[0]->{stack} = $_[1] }
sub set_anchors { $_[0]->{anchors} = $_[1] }
sub schema { return $_[0]->{schema} }
sub cyclic_refs { return $_[0]->{cyclic_refs} }

sub begin {
    my ($self, $ref, $event) = @_;

    my $stack = $self->stack;

    push @$stack, $ref;
    if (defined(my $anchor = $event->{anchor})) {
        $self->anchors->{ $anchor } = { data => $ref->{data} };
    }
}

sub document_start_event {
    my ($self, $event) = @_;
    my $stack = $self->stack;
    my $ref = [];
    push @$stack, { type => 'document', ref => $ref, data => $ref, event => $event };
}

sub document_end_event {
    my ($self, $event) = @_;
    my $stack = $self->stack;
    my $last = pop @$stack;
    my ($type, $ref) = @{ $last }{qw/ type ref /};
    $type eq 'document' or die "Expected mapping, but got $type";
    if (@$stack) {
        die "Got unexpected end of document";
    }
    my $docs = $self->docs;
    push @$docs, $ref->[0];
    $self->set_anchors({});
    $self->set_stack([]);
}

sub mapping_start_event {
    my ($self, $event) = @_;
    my $tag = $event->{tag} || 'tag:yaml.org,2002:map';
    $event = { %$event, tag => $tag };
    my $hash = $self->schema->create_mapping($self, $event);
    my $data = {
        type => 'mapping',
        ref => [],
        data => $hash,
        event => $event,
    };
    $self->begin($data, $event);
}

sub mapping_end_event {
    my ($self, $event) = @_;
    my $stack = $self->stack;

    my $last = pop @$stack;
    my ($type, $ref, $hash, $start_event) = @{ $last }{qw/ type ref data event /};
    $type eq 'mapping' or die "Expected mapping, but got $type";

    $self->schema->mapping_data($self, $hash, $ref);
    push @{ $stack->[-1]->{ref} }, $hash;
    if (defined(my $anchor = $start_event->{anchor})) {
        my $anchors = $self->anchors;
        $anchors->{ $anchor }->{finished} = 1;
    }
    return;
}

sub sequence_start_event {
    my ($self, $event) = @_;
    my $seq = [];
    my $data = { type => 'sequence', ref => [], data => $seq, event => $event };
    $self->begin($data, $event);
}

sub sequence_end_event {
    my ($self, $event) = @_;
    my $stack = $self->stack;
    my $last = pop @$stack;
    my ($type, $ref, $seq, $start_event) = @{ $last }{qw/ type ref data event /};
    $type eq 'sequence' or die "Expected mapping, but got $type";
    @$seq = @$ref;
    push @{ $stack->[-1]->{ref} }, $seq;
    if (defined(my $anchor = $start_event->{anchor})) {
        my $anchors = $self->anchors;
        $anchors->{ $anchor }->{finished} = 1;
    }
    return;
}

sub stream_start_event {
}

sub stream_end_event {}


sub scalar_event {
    my ($self, $event) = @_;
    DEBUG and warn "CONTENT $event->{value} ($event->{style})\n";
    my $value;
    if ($event->{tag}) {
        $value = $self->schema->load_scalar_tag($event);
    }
    else {
        $value = $self->schema->load_scalar($event->{style}, $event->{value});
    }
    if (defined (my $name = $event->{anchor})) {
        $self->anchors->{ $name } = { data => $value, finished => 1 };
    }
    $self->add_scalar($value);
}

sub alias_event {
    my ($self, $event) = @_;
    my $value;
    my $name = $event->{value};
    if (my $anchor = $self->anchors->{ $name }) {
        # We know this is a cyclic ref since the node hasn't
        # been constructed completely yet
        unless ($anchor->{finished} ) {
            my $cyclic_refs = $self->cyclic_refs;
            if ($cyclic_refs ne 'allow') {
                if ($cyclic_refs eq 'fatal') {
                    die "Found cyclic ref";
                }
                if ($cyclic_refs eq 'warn') {
                    $anchor = { data => undef };
                    warn "Found cyclic ref";
                }
                elsif ($cyclic_refs eq 'ignore') {
                    $anchor = { data => undef };
                }
            }
        }
        $value = $anchor->{data};
    }
    $self->add_scalar($value);
}

sub add_scalar {
    my ($self, $value) = @_;

    my $last = $self->stack->[-1];

    my ($type, $ref) = @{ $last }{qw/ type ref /};
    push @$ref, $value;
}

sub stringify_complex {
    my ($self, $data) = @_;
    require Data::Dumper;
    local $Data::Dumper::Quotekeys = 0;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Useqq = 0;
    local $Data::Dumper::Sortkeys = 1;
    my $string = Data::Dumper->Dump([$data], ['data']);
    $string =~ s/^\$data = //;
    return $string;
}

1;
