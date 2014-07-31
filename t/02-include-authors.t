use strict;
use warnings FATAL => 'all';

use utf8;
use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Test::Deep;
use Path::Tiny;
use Git::Wrapper;
use Sort::Versions;

my $tzil = Builder->from_config(
    { dist_root => 't/does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => dist_ini(
                {
                    name     => 'DZT-Sample',
                    abstract => 'Sample DZ Dist',
                    version  => '0.001',
                    author   => [
                        'Anon Y. Moose <anon@null.com>',
                        '김도형 - Keedi Kim <keedi@example.org>',
                    ],
                    license  => 'Perl_5',
                    copyright_holder => 'E. Xavier Ample',
                },
                [ GatherDir => ],
                [ 'Git::Contributors' => { include_authors => 1 } ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

my $root = path($tzil->tempdir)->child('source');
diag 'testing with git repo ', $root;

my $git = Git::Wrapper->new($root);
my $version = $git->version;
diag 'Testing with git version: ', $version;
plan skip_all => "Need git v1.5.0 for 'config' subcommand" if versioncmp($git->version, '1.5.0') < 0;

$git->init;

my $changes = $root->child('Changes');
$changes->spew("Release history for my dist\n\n");
$git->add('Changes');
$git->commit({ message => 'first commit', author => 'Dagfinn Ilmari Mannsåker <ilmari@example.org>' });

$changes->append("- a changelog entry\n");
$git->add('Changes');
$git->commit({ message => 'second commit', author => 'Anon Y. Moose <anon@null.com>' });

$changes->append("- another changelog entry\n");
$git->add('Changes');
$git->commit({ message => 'third commit', author => '김도형 - Keedi Kim <keedi@example.org>' });

$tzil->chrome->logger->set_debug(1);

is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
) or diag 'saw log messages: ', explain $tzil->log_messages;

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        x_contributors => bag(
            'Anon Y. Moose <anon@null.com>',
            '김도형 - Keedi Kim <keedi@example.org>',
            'Dagfinn Ilmari Mannsåker <ilmari@example.org>',
        ),
    }),
    'contributor names are extracted, with authors not stripped',
);

done_testing;
