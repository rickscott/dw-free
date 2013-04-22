#!/usr/bin/perl

use warnings;
use strict;
use 5.010;

use Getopt::Long;


# first, try to determine the user's github username: see if they gave a
# --github-user arg, a single arg, or if the env var GITHUB_USER is set

my $GITHUB_USER;
GetOptions( 'github-user=s' => \$GITHUB_USER );
$GITHUB_USER //= $ARGV[0] if scalar @ARGV == 1;
$GITHUB_USER //= $ENV{GITHUB_USER} if exists $ENV{GITHUB_USER};

die "Can't find your github username! " . 
    "Try bootstrap.pl --github-user <username>\n"
    unless defined $GITHUB_USER;

# github https user url: eg https://rahaeli@github.com/rahaeli
my $github_user_url = "https://$GITHUB_USER\@github.com/$GITHUB_USER";

# see if we can reach a git executable 
system('bash', '-c', 'type git');
die "I can't find git on your system -- is it installed?" unless $? == 0;

# see if LJHOME is defined, and if we can go there 
die "Must set the \$LJHOME environment variable before running this.\n"
    unless defined $ENV{LJHOME};
my $LJHOME = $ENV{LJHOME};
chdir( $LJHOME ) or die "Couldn't chdir to \$LJHOME directory.\n";

# a .git dir in $LJHOME means dw-free is checked out. otherwise, get it  
if ( -d '.git' ) {
    say "Looks like you already have dw-free checked out; skipping...";
}
else {
    say "Checking out dw-free to $LJHOME"; 
    git( 'clone', $github_user_url . '/dw-free.git' , $LJHOME );

    configure_dw_upstream( 'dw-free' );
}

# similar dance for dw-nonfree 
if ( -d "$LJHOME/ext/dw-nonfree/.git" ) {
    say "Looks like you already have dw-nonfree checked out; skipping...";
}
else {
    say "Checking out dw-nonfree to $LJHOME/ext"; 

    chdir( "$LJHOME/ext" ) or die "Couldn't chdir to ext directory.\n";
    git( 'clone', $github_user_url . '/dw-nonfree.git' );

    chdir( "$LJHOME/ext/dw-nonfree" ) 
        or die "Couldn't chdir to dw-nonfree directory.\n";

    configure_dw_upstream( 'dw-nonfree' );
}

# a little syntactic sugar: run a git command 
sub git {
    system( 'git', @_ ) or die "failure trying to run: git @_\n"; 
}

sub configure_dw_upstream {
    my ($repo) = @_;

    my $dw_repo_url = "https://github.com/dreamwidth/$repo";
    git( qw{remote add dreamwidth}, $dw_repo_url );
    git( qw{fetch dreamwidth} );
    git( qw{branch --set-upstream develop dreamwidth/develop} );
    git( qw{branch --set-upstream master dreamwidth/master} );
}

# finished :-)
chdir( $LJHOME );
say "Done! You probably want to set up the MySQL database next:"; 
say "http://wiki.dwscoalition.org/notes/Dreamwidth_Scratch_Installation#Database_setup";

