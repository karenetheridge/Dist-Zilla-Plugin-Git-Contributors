use strict;
use warnings FATAL => 'all';
package GitSetup;

use Test::More;
use Git::Wrapper;
use Sort::Versions;

use parent 'Exporter';
our @EXPORT = qw(git_wrapper);

# does some preliminary setup of the test Git::Wrapper object
# and a sanity check
sub git_wrapper
{
    my $root = shift;

    diag 'testing with git repo ', $root;

    my $git = Git::Wrapper->new($root);
    my $version = $git->version;
    my $err = $git->ERR; diag explain @$err if @$err;

    diag 'Testing with git version: ', $version;
    plan skip_all => "Need git v1.5.0 for 'config' subcommand" if versioncmp($version, '1.5.0') < 0;

    $git->init;
    $err = $git->ERR; diag explain @$err if @$err;

    $git->config('user.name', 'Test User');
    $git->config('user.email', 'test@example.com');

    $git;
}

1;
