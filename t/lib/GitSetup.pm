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

    plan skip_all => 'Need mysysgit v1.7.10 for proper unicode support on windows (https://github.com/msysgit/msysgit/wiki/Git-for-Windows-Unicode-Support)'
        if $^O eq 'MSWin32' and versioncmp($version, '1.7.10') < 0;

    $git->init;
    $err = $git->ERR; diag explain @$err if @$err;

    $git->config('user.name', 'Test User');
    $git->config('user.email', 'test@example.com');

    # see https://github.com/msysgit/msysgit/wiki/Git-for-Windows-Unicode-Support
    # and http://ox.no/posts/how-to-combine-git-windows-and-non-ascii-letters
    if ($^O eq 'MSWin32')
    {
        $git->config('i18n.logoutputencoding', 'utf-8');
        $git->config('i18n.commitencoding', 'utf-8');
        $ENV{LESSCHARSET} = 'utf-8';
    }

    $git;
}

1;
