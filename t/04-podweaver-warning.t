use strict;
use warnings FATAL => 'all';

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Test::Deep;
use Path::Tiny;

use Test::Requires qw(Dist::Zilla::Plugin::PodWeaver Pod::Weaver::Section::Contributors);

use lib 't/lib';
use GitSetup;

$Pod::Weaver::Section::Contributors::VERSION = '0.007';

{
    my $tzil = Builder->from_config(
        { dist_root => 't/does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ PodWeaver => ],
                    [ 'Git::Contributors' ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
                path(qw(source weaver.ini)) => "[Contributors]\n",
            },
        },
    );

    my $root = path($tzil->tempdir)->child('source');
    my $git = git_wrapper($root);

    my $changes = $root->child('Changes');
    $changes->spew("Release history for my dist\n\n");
    $git->add('Changes');
    $git->commit({ message => 'first commit', author => 'Anon Y. Moose <anon@null.com>' });

    $tzil->chrome->logger->set_debug(1);

    is(
        exception { $tzil->build },
        undef,
        'build proceeds normally',
    ) or diag 'saw log messages: ', explain $tzil->log_messages;

    cmp_deeply(
        $tzil->log_messages,
        superbagof(
            re(qr/^\[Git::Contributors\] WARNING! You appear to ...+ version 0.008!$/),
        ),
        'got a warning about [Contributors] being too old',
    ) or diag 'saw log messages: ', explain $tzil->log_messages;
}

# now test again using *identical* conditions, except there are no contributor names in distmeta...

{
    my $tzil = Builder->from_config(
        { dist_root => 't/does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ PodWeaver => ],
                    [ 'Git::Contributors' ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
                path(qw(source weaver.ini)) => "[Contributors]\n",
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

    is(
        (grep { /^\[Git::Contributors\] WARNING! You appear to ...+ version 0.008!$/ } @{$tzil->log_messages}),
        0,
        'got no warning about [Contributors] being too old',
    ) or diag 'saw log messages: ', explain $tzil->log_messages;
}

done_testing;
