use strict;
use warnings;
package YAML::PP::Grammar;

our $VERSION = '0.000'; # VERSION

use base 'Exporter';

our @EXPORT_OK = qw/ $GRAMMAR /;

our $GRAMMAR = {
    RULE_ALIAS_KEY_OR_NODE => {
        ALIAS => {
            match => 'cb_stack_alias',
            EOL => { match => 'cb_alias_from_stack', new => 'NODE' },
            WS => {
                COLON => {
                    match => 'cb_alias_key_from_stack',
                    EOL => { new => 'FULLNODE', return => 1 },
                    WS => { new => 'MAPVALUE' },
                },
            },
        },
    },
    RULE_COMPLEX => {
        QUESTION => {
            match => 'cb_questionstart',
            EOL => { new => 'FULLNODE', return => 1 },
            WS => { new => 'FULLNODE', return => 1},
        },
    },
    NODETYPE_COMPLEX => {
        COLON => {
            match => 'cb_complexcolon',
            EOL => { new => 'FULLNODE' , return => 1},
            WS => { new => 'FULLNODE' , return => 1},
        },
        DEFAULT => {
            match => 'cb_empty_complexvalue',
            QUESTION => {
                match => 'cb_question',
                EOL => { new => 'FULLNODE' , return => 1},
                WS => { new => 'FULLNODE' , return => 1},
            },
            DEFAULT => { new => 'NODETYPE_MAP' },
        },
    },
    RULE_SINGLEQUOTED_KEY_OR_NODE => {
        SINGLEQUOTE => {
            SINGLEQUOTED_SINGLE => {
                match => 'cb_stack_singlequoted_single',
                SINGLEQUOTE => {
                    EOL => { match => 'cb_scalar_from_stack', new => 'NODE' },
                    'WS?' => {
                        COLON => {
                            match => 'cb_mapkey_from_stack',
                            EOL => { new => 'FULLNODE' , return => 1},
                            WS => { new => 'MAPVALUE' },
                        },
                    },
                },
            },
            SINGLEQUOTED_LINE => {
                match => 'cb_stack_singlequoted',
                LB => { new => 'MULTILINE_SINGLEQUOTED'  },
            },
        },
    },
    MULTILINE_SINGLEQUOTED => {
        SINGLEQUOTED_END => {
            match => 'cb_stack_singlequoted',
            SINGLEQUOTE => {
                EOL => { match => 'cb_scalar_from_stack', new => 'NODE' },
            },
        },
        SINGLEQUOTED_LINE => {
            match => 'cb_stack_singlequoted',
            LB => { new => 'MULTILINE_SINGLEQUOTED' },
        },
    },
    RULE_DOUBLEQUOTED_KEY_OR_NODE => {
        DOUBLEQUOTE => {
            DOUBLEQUOTED_SINGLE => {
                match => 'cb_stack_doublequoted_single',
                DOUBLEQUOTE => {
                    EOL => { match => 'cb_scalar_from_stack', new => 'NODE' },
                    'WS?' => {
                        COLON => {
                            match => 'cb_mapkey_from_stack',
                            EOL => { new => 'FULLNODE' , return => 1},
                            WS => { new => 'MAPVALUE' },
                        },
                        DEFAULT => { match => 'cb_scalar_from_stack', new => 'ERROR' },
                    },
                },
            },
            DOUBLEQUOTED_LINE => {
                match => 'cb_stack_doublequoted',
                LB => { new => 'MULTILINE_DOUBLEQUOTED'  },
            },
        },
    },
    MULTILINE_DOUBLEQUOTED => {
        DOUBLEQUOTED_END => {
            match => 'cb_stack_doublequoted',
            DOUBLEQUOTE => {
                EOL => { match => 'cb_scalar_from_stack', new => 'NODE' },
            },
        },
        DOUBLEQUOTED_LINE => {
            match => 'cb_stack_doublequoted',
            LB => { new => 'MULTILINE_DOUBLEQUOTED'  },
        },
    },
    RULE_PLAIN_KEY_OR_NODE => {
        SCALAR => {
            match => 'cb_stack_plain',
            COMMENT_EOL => { match => 'cb_plain_single', new => 'NODE' },
            EOL => { match => 'cb_multiscalar_from_stack', new => 'NODE' },
            'WS?' => {
                COLON => {
                    match => 'cb_mapkey_from_stack',
                    EOL => { new => 'FULLNODE' , return => 1},
                    'WS' => { new => 'MAPVALUE' },
                },
            },
        },
        COLON => {
            match => 'cb_mapkey_from_stack',
            EOL => { new => 'FULLNODE' , return => 1},
            'WS' => { new => 'MAPVALUE' },
        },
    },
    RULE_PLAIN => {
        SCALAR => {
            match => 'cb_stack_plain',
            COMMENT_EOL => { match => 'cb_multiscalar_from_stack', new => 'NODE' },
            EOL => { match => 'cb_multiscalar_from_stack', new => 'NODE' },
        },
    },
    NODETYPE_MAP => {
        QUESTION => {
            match => 'cb_question',
            EOL => { new => 'FULLNODE' , return => 1},
            WS => { new => 'FULLNODE' , return => 1},
        },
        ALIAS => {
            match => 'cb_mapkey_alias',
            WS => {
                COLON => {
                    EOL => { new => 'FULLNODE' , return => 1},
                    WS => { new => 'MAPVALUE' },
                },
            },
        },
        DOUBLEQUOTE => {
            DOUBLEQUOTED_SINGLE => {
                match => 'cb_doublequoted_key',
                DOUBLEQUOTE => {
                    'WS?' => {
                        COLON => {
                            EOL => { new => 'FULLNODE' , return => 1},
                            WS => { new => 'MAPVALUE' },
                        },
                    },
                },
            },
        },
        SINGLEQUOTE => {
            SINGLEQUOTED_SINGLE => {
                match => 'cb_singlequoted_key',
                SINGLEQUOTE => {
                    'WS?' => {
                        COLON => {
                            EOL => { new => 'FULLNODE' , return => 1},
                            WS => { new => 'MAPVALUE' },
                        },
                    },
                },
            },
        },
        SCALAR => {
            match => 'cb_mapkey',
            'WS?' => {
                COLON => {
                    EOL => { new => 'FULLNODE' , return => 1},
                    WS => { new => 'MAPVALUE' },
                },
            },
        },
        COLON => {
            match => 'cb_empty_mapkey',
            EOL => { new => 'FULLNODE' , return => 1},
            WS => { new => 'MAPVALUE' },
        },
    },
    NODETYPE_MAPSTART => {
        QUESTION => {
            match => 'cb_questionstart',
            EOL => { new => 'FULLNODE' , return => 1},
            WS => { new => 'FULLNODE' , return => 1},
        },
        DOUBLEQUOTE => {
            DOUBLEQUOTED => {
                match => 'cb_doublequotedstart',
                DOUBLEQUOTE => {
                    'WS?' => {
                        COLON => {
                            EOL => { new => 'FULLNODE' , return => 1},
                            WS => { new => 'MAPVALUE' },
                        },
                    },
                },
            },
        },
        SINGLEQUOTE => {
            SINGLEQUOTED => {
                match => 'cb_singleequotedstart',
                SINGLEQUOTE => {
                    'WS?' => {
                        COLON => {
                            EOL => { new => 'FULLNODE' , return => 1},
                            WS => { new => 'MAPVALUE' },
                        },
                    },
                },
            },
        },
        SCALAR => {
            match => 'cb_mapkeystart',
            'WS?' => {
                COLON => {
                    EOL => { new => 'FULLNODE' , return => 1},
                    WS => { new => 'MAPVALUE' },
                },
            },
        },
    },
    RULE_SEQSTART => {
        DASH => {
            match => 'cb_seqstart',
            EOL => { new => 'FULLNODE' , return => 1},
            WS => { new => 'FULLNODE' , return => 1},
        },
    },
    NODETYPE_SEQ => {
        DASH => {
            match => 'cb_seqitem',
            EOL => { new => 'FULLNODE' , return => 1},
            WS => { new => 'FULLNODE' , return => 1},
        },
    },
    RULE_BLOCK_SCALAR => {
        LITERAL => { match => 'cb_block_scalar', new => 'NODE' },
        FOLDED => { match => 'cb_block_scalar', new => 'NODE' },
    },
#    RULE_FLOW_MAP => [
#        [['FLOW_MAP_START', 'cb_flow_map'],
#            \'ERROR'
#        ],
#    ],
#    RULE_FLOW_SEQ => [
#        [['FLOW_SEQ_START', 'cb_flow_seq'],
#            \'ERROR'
#        ],
#    ],


    FULL_MAPKEY => {
        ANCHOR => {
            match => 'cb_anchor',
            WS => {
                TAG => {
                    match => 'cb_tag',
                    WS => { new => 'NODETYPE_MAPKEY'  },
                },
                DEFAULT => { new => 'NODETYPE_MAPKEY' },
            },
        },
        TAG => {
            match => 'cb_tag',
            WS => {
                ANCHOR => {
                    match => 'cb_anchor',
                    WS => { new => 'NODETYPE_MAPKEY'  },
                },
                DEFAULT => { new => 'NODETYPE_MAPKEY' },
            },
        },
        DEFAULT => { new => 'NODETYPE_MAPKEY' },
    },

    FULLNODE_ANCHOR => {
        TAG => {
            match => 'cb_tag',
            EOL => { match => 'cb_property_eol', new => 'FULLNODE_TAG_ANCHOR' , return => 1},
            WS => {
                ANCHOR => {
                    match => 'cb_anchor',
                    WS => { new => 'NODETYPE_MAPSTART'  },
                },
                DEFAULT => { new => 'NODETYPE_NODE' }
            },
        },
        ANCHOR => {
            match => 'cb_anchor',
            WS => {
                TAG => {
                    match => 'cb_tag',
                    WS => { new => 'NODETYPE_MAPSTART'  },
                },
                DEFAULT => { new => 'NODETYPE_MAPSTART' },
            },
        },
        DEFAULT => { new => 'NODETYPE_NODE' },
    },
    FULLNODE_TAG => {
        ANCHOR => {
            match => 'cb_anchor',
            EOL => { match => 'cb_property_eol', new => 'FULLNODE_TAG_ANCHOR' , return => 1},
            WS => {
                TAG => {
                    match => 'cb_tag',
                    WS => { new => 'NODETYPE_MAPSTART'  },
                },
                DEFAULT => { new => 'NODETYPE_NODE', },
            },
        },
        TAG => {
            match => 'cb_tag',
            WS => {
                ANCHOR => {
                    match => 'cb_anchor',
                    WS => { new => 'NODETYPE_MAPSTART'  },
                },
                DEFAULT => { new => 'NODETYPE_MAPSTART' },
            },
        },
        DEFAULT => { new => 'NODETYPE_NODE' },
    },
    FULLNODE_TAG_ANCHOR => {
        ANCHOR => {
            match => 'cb_anchor',
            WS => {
                TAG => {
                    match => 'cb_tag',
                    WS => { new => 'NODETYPE_MAPSTART'  },
                },
                DEFAULT => { new => 'NODETYPE_MAPSTART' },
            },
        },
        TAG => {
            match => 'cb_tag',
            WS => {
                ANCHOR => {
                    match => 'cb_anchor',
                    WS => { new => 'NODETYPE_MAPSTART'  },
                },
                DEFAULT => { new => 'NODETYPE_MAPSTART' },
            },
        },
        DEFAULT => { new => 'NODETYPE_NODE' }
    },
    FULLNODE => {
        ANCHOR => {
            match => 'cb_anchor',
            EOL => { match => 'cb_property_eol', new => 'FULLNODE_ANCHOR' , return => 1},
            WS => {
                TAG => {
                    match => 'cb_tag',
                    EOL => { match => 'cb_property_eol', new => 'FULLNODE_TAG_ANCHOR' , return => 1},
                    # SCALAR
                    WS => { new => 'NODETYPE_NODE'  },
                },
                # SCALAR
                DEFAULT => { new => 'NODETYPE_NODE' },
            },
        },
        TAG => {
            match => 'cb_tag',
            EOL => { match => 'cb_property_eol', new => 'FULLNODE_TAG' , return => 1},
            WS => {
                ANCHOR => {
                    match => 'cb_anchor',
                    EOL => { match => 'cb_property_eol', new => 'FULLNODE_TAG_ANCHOR' , return => 1},
                    # SCALAR
                    WS => { new => 'NODETYPE_NODE'  },
                },
                # SCALAR
                DEFAULT => { new => 'NODETYPE_NODE' },
            },
        },
        DEFAULT => { new => 'PREVIOUS' },
    },
};

my %TYPE2RULE = (
    NODETYPE_MAPKEY => {
        %{ $GRAMMAR->{NODETYPE_MAP} },
    },
    NODETYPE_STARTNODE => {
        %{ $GRAMMAR->{RULE_SINGLEQUOTED_KEY_OR_NODE} },
        %{ $GRAMMAR->{RULE_DOUBLEQUOTED_KEY_OR_NODE} },
        %{ $GRAMMAR->{RULE_BLOCK_SCALAR} },
        %{ $GRAMMAR->{RULE_PLAIN} },
    },
    NODETYPE_MAPVALUE => {
        %{ $GRAMMAR->{RULE_ALIAS_KEY_OR_NODE} },
        %{ $GRAMMAR->{RULE_SINGLEQUOTED_KEY_OR_NODE} },
        %{ $GRAMMAR->{RULE_DOUBLEQUOTED_KEY_OR_NODE} },
        %{ $GRAMMAR->{RULE_BLOCK_SCALAR} },
        %{ $GRAMMAR->{RULE_PLAIN} },
    },
    NODETYPE_NODE => {
        %{ $GRAMMAR->{RULE_SEQSTART} },
        %{ $GRAMMAR->{RULE_COMPLEX} },
        %{ $GRAMMAR->{RULE_SINGLEQUOTED_KEY_OR_NODE} },
        %{ $GRAMMAR->{RULE_DOUBLEQUOTED_KEY_OR_NODE} },
        %{ $GRAMMAR->{RULE_BLOCK_SCALAR} },
        %{ $GRAMMAR->{RULE_ALIAS_KEY_OR_NODE} },
        %{ $GRAMMAR->{RULE_PLAIN_KEY_OR_NODE} },
    },
);

%$GRAMMAR = (
    %$GRAMMAR,
    %TYPE2RULE,
);

1;
