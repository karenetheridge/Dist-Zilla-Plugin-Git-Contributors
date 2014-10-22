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

my $tempdir = no_git_tempdir();
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
                        'Anne O\'Thor <author@example.com>',
                    ],
                    license  => 'Perl_5',
                    copyright_holder => 'E. Xavier Ample',
                },
                [ GatherDir => ],
                [ MetaConfig => ],
                [ 'Git::Contributors' ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
        tempdir_root => $tempdir->stringify,
    },
);

my $root = path($tzil->tempdir)->child('source');
my $git = git_wrapper($root);

my $changes = $root->child('Changes');
$changes->spew("Release history for my dist\n\n");
$git->add('Changes');
$git->commit({ message => 'first commit', author => 'Hey Jude <jude@example.org>' });

$changes->append("- a changelog entry\n");
$git->add('Changes');
$git->commit({ message => 'second commit', author => 'Anon Y. Moose <anon@null.com>' });

$changes->append("- another changelog entry\n");
$git->add('Changes');
$git->commit({ message => 'third commit', author => 'Foo Bar <foo@bar.com>' });

$tzil->chrome->logger->set_debug(1);

is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        x_contributors => [
            'Foo Bar <foo@bar.com>',
            'Hey Jude <jude@example.org>',
        ],
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::Git::Contributors',
                    config => {
                        'Dist::Zilla::Plugin::Git::Contributors' => {
                            include_authors => 0,
                            include_releaser => 1,
                            order_by => 'name',
                            paths => [],
                        },
                    },
                    name => 'Git::Contributors',
                    version => ignore,
                },
            ),
        }),
    }),
    'contributor names are extracted, with authors not included',
) or diag 'got distmeta: ', explain $tzil->distmeta;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
