use strict;
use warnings FATAL => 'all';

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Test::Deep;
use Path::Tiny;

use lib 't/lib';
use GitSetup;

my $tzil = Builder->from_config(
    { dist_root => 't/does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ 'Git::Contributors' ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

my $root = path($tzil->tempdir)->child('source');
my $git = git_wrapper($root);

# if we don't initialize the repo *and* make a commit in it, git will instead
# find the real distribution repo, not the test one.

my $changes = $root->child('Changes');
$changes->spew("Release history for my dist\n\n");
$git->add('Changes');
$git->commit({ message => 'first commit', author => $tzil->authors->[0] });

$tzil->chrome->logger->set_debug(1);

is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
) or diag 'saw log messages: ', explain $tzil->log_messages;

cmp_deeply(
    $tzil->distmeta,
    # TODO: replace with Test::Deep::notexists($key)
    code(sub {
        !exists $_[0]->{x_contributors} ? 1 : (0, 'x_contributors exists');
    }),
    'no metadata is added when there are no (non-author) contributors found',
)
or diag 'got distmeta: ', explain $tzil->distmeta;

done_testing;
