use strict;
use warnings;
package YAML::PP::Schema::Perl;

our $VERSION = '0.000'; # VERSION

use base 'YAML::PP::Schema';

use Scalar::Util qw/ blessed reftype /;
use YAML::PP::Common qw/ YAML_QUOTED_SCALAR_STYLE /;

use constant PREFIX_PERL => '!perl/';

sub register {
    my ($self, %args) = @_;
    my $schema = $args{schema};

    $schema->add_resolver(
        match => [ equals => '' => '' ],
    );

    $schema->add_representer(
        undefined => sub {
            my ($rep, $node) = @_;
            $node->{data} = '';
            $node->{style} = YAML_QUOTED_SCALAR_STYLE;
            return 1;
        },
    );

    $schema->add_representer(
        scalarref => 1,
        code => sub {
            my ($rep, $node) = @_;
            $node->{tag} = PREFIX_PERL . "scalar";
            if (blessed($node->{value})) {
                $node->{tag} .= ':' . blessed($node->{value});
            }
            %{ $node->{data} } = ( '=' => ${ $node->{value} } );
        },
    );
    $schema->add_representer(
        coderef => 1,
        code => sub {
            my ($rep, $node) = @_;
            require B::Deparse;
            my $deparse = B::Deparse->new("-p", "-sC");
            $node->{tag} = PREFIX_PERL . "code";
            $node->{data} = $deparse->coderef2text($node->{value});
        },
    );

    $schema->add_representer(
        class_matches => 1,
        code => sub {
            my ($rep, $node) = @_;
            my $blessed = blessed $node->{value};
            $node->{tag} = sprintf PREFIX_PERL . "%s:%s",
                lc($node->{reftype}), $blessed;
            if ($node->{reftype} eq 'HASH') {
                $node->{data} = $node->{value};
            }
            elsif ($node->{reftype} eq 'ARRAY') {
                $node->{data} = $node->{value};
            }

            # Fun with regexes in perl versions!
            elsif ($node->{reftype} eq 'REGEXP') {
                if ($blessed eq 'Regexp') {
                    $node->{tag} = sprintf PREFIX_PERL . "%s",
                        lc($node->{reftype});
                }
                $node->{data} = "$node->{value}";
            }
            elsif ($node->{reftype} eq 'SCALAR') {

                # in perl <= 5.10 regex reftype(regex) was SCALAR
                if ($blessed eq 'Regexp') {
                    $node->{tag} = PREFIX_PERL . 'regexp';
                    $node->{data} = "$node->{value}";
                }

                # In perl <= 5.10 there seemed to be no better pure perl
                # way to detect a blessed regex?
                elsif (
                    $] <= 5.010001
                    and not defined ${ $node->{value} }
                    and $node->{value} =~ m/^\(\?/
                ) {
                    $node->{tag} = PREFIX_PERL . 'regexp:' . $blessed;
                    $node->{data} = "$node->{value}";
                }
                else {
                    # phew, just a simple scalarref
                    %{ $node->{data} } = ( '=' => ${ $node->{value} } );
                }
            }

            elsif ($node->{reftype} eq 'CODE') {
                require B::Deparse;
                my $deparse = B::Deparse->new("-p", "-sC");
                $node->{data} = $deparse->coderef2text($node->{value});
            }
            else {
                die "Reftype '$node->{reftype}' not implemented";
            }

            return 1;
        },
    );
    return;
}

1;
