#!/usr/bin/perl
use strict;
use warnings;

my @filelist;

# List of expanded flags
my %arglist = (
    "show-all"          => 0,
    "number-nonblank"   => 0,
    "show-ends"         => 0,
    "number"            => 0,
    "squeeze-blank"     => 0,
    "show-tabs"         => 0,
    "show-nonprinting"  => 0,
);

# List of equivalent args
my %equivalentargs = (
    "A"                 => ["show-all"],
    "b"                 => ["number-nonblank"],
    "e"                 => ["show-nonprinting", "show-ends"],
    "E"                 => ["show-ends"],
    "n"                 => ["number"],
    "s"                 => ["squeeze-blank"],
    "t"                 => ["show-nonprinting", "show-tabs"],
    "T"                 => ["show-tabs"],
    "u"                 => [],
    "v"                 => ["show-nonprinting"]
);

# Octal codes and their escape codes
my %oct = (
    '\000'              => "^@",
    '\001'              => "^A",
    '\002'              => "^B",
    '\003'              => "^C",
    '\004'              => "^D",
    '\005'              => "^E",
    '\006'              => "^F",
    '\007'              => "^G",
    '\010'              => "^H",
    '\013'              => "^K",
    '\014'              => "^L",
    '\015'              => "^M",
    '\016'              => "^N",
    '\017'              => "^O",
    '\020'              => "^P",
    '\021'              => "^Q",
    '\022'              => "^R",
    '\023'              => "^S",
    '\024'              => "^T",
    '\025'              => "^U",
    '\026'              => "^V",
    '\027'              => "^W",
    '\030'              => "^X",
    '\031'              => "^Y",
    '\032'              => "^Z",
    '\033'              => "^[",
    '\034'              => "^\\",
    '\035'              => "^]",
    '\036'              => "^^",
    '\037'              => "^_",
    '\177'              => "^?"
);

# Parse arguments
foreach my $opt ( @ARGV ) {
    if( substr( $opt, 0, 1 ) eq '-' ) {

        # If --{arg}
        if( substr( $opt, 1, 1 ) eq '-' ) {
            my $argname = substr( $opt, 2 );
            if ( exists $arglist{ $argname } ) {
                $arglist{ $argname } = 1
            } else { die "$0: unrecognized option: '$argname'\n" }

        # If -{arg}
        } else {

            # Handle "-" as STDIN
            my $argname = substr( $opt, 1 );
            if( $argname eq "" ) {
                push( @filelist, "-" );
                next;
            }
            elsif( exists $equivalentargs{ $argname } ) {
                # Runs through the equivalent args and sets them to 1
                foreach my $arg ( @{ $equivalentargs{ $argname } } ) {
                    $arglist{ $arg } = 1;
                }
            } else { die "$0: unrecognized option: '$argname'\n" }
        }

    # Interpret non arguments as files
    } else {
        push( @filelist, $opt );
    }
}


if( $arglist{ "show-all" } ) {
    $arglist{ "show-nonprinting" } = 1;
    $arglist{ "show-ends" } = 1;
    $arglist{ "show-tabs" } = 1;
}

# Read from STDIN if no files given
if( scalar( @filelist ) == 0 ) {
    push( @filelist, "-" ); 
}

# Debugging output
# foreach my $key ( keys %arglist ) {
#     warn "$key: $arglist{ $key }\n";
# }

# Loop through the file list, printing each
foreach my $file ( @filelist ) {

    # Check permissions
    die "$0: $file: Permission denied\n" unless -r $file;

    # Handle directories
    if( -d $file ) {
        die "$0: $file: Is a directory\n";
    }
    else {
        my $filehandle = undef;

        # Handle dash as STDIN
        if( $file eq "-" ) {
            $filehandle = \*STDIN;
        }
        else {
            open( $filehandle, "<", $file ) or
                die "$0: $file: no such file or directory\n";
        }

        my $count = 1;
        my $blank = 0;
        while( <$filehandle> ) {

            # Handle --squeeze-blank
            if( $arglist{ "squeeze-blank" } ) {
                # If the line is blank and the blank option is set, skip
                if( $_ eq "\n" ) {
                    if( $blank ) {
                        next;
                    }
                    # If the blank option isn't set, set it and continue
                    else {
                        $blank = 1;
                    }
                }
                else {
                    $blank = 0;
                }
            }

            # Handle --number-nonblank
            if( $arglist{ "number-nonblank" } ) {
                # If the line is nonblank, don't add the number
                unless( $_ eq "\n" ) {
                    $_ = sprintf( "%6d  %s", $count, $_ );
                }
            }
            # Handle --number, don't override if --number-nonblank is set
            elsif( $arglist{ "number" } ) {
                $_ = sprintf( "%6d  %s", $count, $_ );
            }

            # Handle --show-ends
            if( $arglist{ "show-ends" } ) {
                $_ =~ s/\n/\$\n/g;
            }

            # Handle --show-tabs
            if( $arglist{ "show-tabs" } ) {
                $_ =~ s/\t/^I/g;
            }

            if( $arglist{ "show-nonprinting" } && $_ =~ m/[\000-\010\013-\037\177]/ ) {
                foreach my $reg  ( keys %oct ) {
                    $_ =~ s/$reg/$oct{ $reg }/g;
                }
            }

            print $_;

            $count++;
        }
        close( $filehandle );
    }
}
