use strict;
use warnings FATAL => 'all';

use utf8;
use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Test::Deep;
use Path::Tiny;

use lib 't/lib';
use GitSetup;

binmode $_, ':utf8' foreach map { Test::Builder->new->$_ } qw(output failure_output todo_output);
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

local $TODO = 'tests of git commits with unicode do not seem to work yet; see genehack/Git-Wrapper/#52'
    if $^O eq 'MSWin32';

my $tzil = Builder->from_config(
    { dist_root => 't/does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => dist_ini(
                {
                    name     => 'DZT-Sample',
                    abstract => 'Sample DZ Dist',
                    version  => '0.001',
                    author   => 'Anne O\'Thor <author@example.com>',
                    license  => 'Perl_5',
                    copyright_holder => 'E. Xavier Ample',
                },
                [ GatherDir => ],
                [ MetaConfig => ],
                [ 'Git::Contributors' => { include_authors => 1 } ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

my $root = path($tzil->tempdir)->child('source');
my $git = git_wrapper($root);

my $changes = $root->child('Changes');
$changes->spew("Release history for my dist\n\n");
$git->add('Changes');
my $ilmari = 'Dagfinn Ilmari Mannsåker <ilmari@example.org>';
$git->commit({ message => 'first commit', author => $ilmari });

$changes->append("- a changelog entry\n");
$git->add('Changes');
$git->commit({ message => 'second commit', author => 'Anne O\'Thor <author@example.com>' });

$changes->append("- another changelog entry\n");
$git->add('Changes');
$git->commit({ message => 'third commit', author => 'Z. Tinman <ztinman@example.com>' });

$changes->append("- yet another changelog entry\n");
$git->add('Changes');
$git->commit({ message => 'fourth commit', author => '김도형 - Keedi Kim <keedi@example.org>', });

$changes->append("- still yet another changelog entry\n");
$git->add('Changes');
$git->commit({ message => 'fifth commit', author => 'Évelyne Brochu <evelyne@example.com>' });

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
            'Anne O\'Thor <author@example.com>',
            'Dagfinn Ilmari Mannsåker <ilmari@example.org>',
            'Évelyne Brochu <evelyne@example.com>',
            'Z. Tinman <ztinman@example.com>',
            '김도형 - Keedi Kim <keedi@example.org>',
        ],
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::Git::Contributors',
                    config => {
                        'Dist::Zilla::Plugin::Git::Contributors' => {
                            include_authors => 1,
                            include_releaser => 1,
                            order_by => 'name',
                        },
                    },
                    name => 'Git::Contributors',
                    version => ignore,
                },
            ),
        }),
    }),
    'contributor names are extracted properly, without mojibake, with names sorted using unicode collation',
) or diag 'got distmeta: ', explain $tzil->distmeta;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
