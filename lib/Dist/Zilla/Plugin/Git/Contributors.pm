use strict;
use warnings;
package Dist::Zilla::Plugin::Git::Contributors;
# ABSTRACT: Add contributor names from git to your distribution
# KEYWORDS: plugin distribution metadata git contributors authors commits
# vim: set ts=8 sw=4 tw=78 et :

use Moose;
with 'Dist::Zilla::Role::MetaProvider';

use List::Util 1.33 'none';
use Git::Wrapper;
use Try::Tiny;
use Safe::Isa;
use Path::Tiny;
use Data::Dumper;
use namespace::autoclean;

has include_authors => (
    is => 'ro', isa => 'Bool',
    default => 0,
);

has include_releaser => (
    is => 'ro', isa => 'Bool',
    default => 1,
);

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        include_authors => $self->include_authors,
        include_releaser  => $self->include_releaser,
    };

    return $config;
};

sub metadata
{
    my $self = shift;

    my $contributors = $self->_contributors;
    return if not @$contributors;

    $self->_check_podweaver;
    +{ x_contributors => $contributors };
}

sub _contributors
{
    my $self = shift;

    # figure out if we're in a git repo or not
    my $in_repo;
    try {
        $in_repo = $self->_git(RUN => 'status');
    }
    catch {
        $self->log($_->error) if $_->$_isa('Git::Wrapper::Exception');
    };

    return [] if not $in_repo;

    my @data = $self->_git(shortlog => 'HEAD', { email => 1, summary => 1 });

    my @contributors = map { utf8::decode($_); m/^\s*\d+\s*(.*)$/g; } @data;

    $self->log_debug([ 'extracted contributors from git: %s',
        sub { Data::Dumper->new([ \@contributors ])->Indent(2)->Terse(1)->Dump } ]);

    if (not $self->include_authors)
    {
        my $authors = $self->zilla->authors;
        @contributors = grep {
            my $contributor = $_;
            none { $contributor eq $_ } @$authors;
        } @contributors;
    }

    if (not $self->include_releaser)
    {
        my $releaser = $self->_releaser;
        @contributors = grep { $_ ne $releaser } @contributors;
    }

    return \@contributors;
}

sub _releaser
{
    my $self = shift;

    my ($username) = $self->_git(config => 'user.name');
    my ($email) = $self->_git(config => 'user.email');

    return if not $username or not $email;
    $username . ' <' . $email . '>';
}

sub _check_podweaver
{
    my $self = shift;

    # check if the module is loaded, not just that it is installed
    $self->log('WARNING! You appear to be using Pod::Weaver::Section::Contributors, but it is not new enough to take data directly from distmeta. Upgrade to version 0.008!')
        if eval { Pod::Weaver::Section::Contributors->VERSION(0); 1 }
            and not eval { Pod::Weaver::Section::Contributors->VERSION(0.007001); 1 };
}

has __git => (
    is => 'ro',
    isa => 'Git::Wrapper',
    lazy => 1,
    default => sub { Git::Wrapper->new(path('.')->absolute->stringify) },
);

sub _git
{
    my ($self, $command, @args) = @_;

    my $git = $self->__git;
    my @result = $git->$command(@args);
    my $err = $git->ERR; $self->log(@$err) if @$err;
    return @result;
}

__PACKAGE__->meta->make_immutable;
__END__

=pod

=head1 SYNOPSIS

In your F<dist.ini>:

    [Git::Contributors]

=head1 DESCRIPTION

This is a L<Dist::Zilla> plugin that extracts all names and email addresses
from git commits in your repository and adds them to the distribution metadata
under the C<x_contributors> key.  It takes a minimalist approach to this -- no
data is stuffed into other locations, including stashes -- if other plugins
wish to work with this information, they should extract it from the
distribution metadata.

=head1 CONFIGURATION OPTIONS

=head2 C<include_authors>

When true, authors are added to the list of contributors. When false, authors
are filtered out of the list of contributors.  Defaults to false.

=head2 C<include_releaser>

Defaults to true; set to false to remove the current user (who is doing the
distribution release) from the contributors list. It is applied after
C<include_authors>, so you will be removed from the list even if you are (one
of the) distribution author(s) and C<include_authors = 1>.

=for stopwords metacpan

For most distributions, C<< include_authors = 1, include_releaser = 0 >> seems
to be the right combination of configs to use, particularly for how
distributions are displayed on L<metacpan|http://metacpan.org>. Perhaps these
should be the defaults?

=for stopwords canonicalizing

=head1 CANONICALIZING NAMES AND ADDRESSES

If you or a contributor uses multiple names and/or email addresses to make
commits and would like them mapped to a canonical value, you can do this by
adding a F<.mailmap> file to your git repository, with entries formatted as
described in "MAPPING AUTHORS" in C<git help shortlog>
(L<https://www.kernel.org/pub/software/scm/git/docs/git-shortlog.html>).

=head1 ADDING CONTRIBUTORS TO POD DOCUMENTATION

You can add the contributor names to your module documentation by using
L<Pod::Weaver> in conjunction with L<Pod::Weaver::Section::Contributors>.

=head1 UNICODE SUPPORT

=for stopwords ascii

This module aims to properly handle non-ascii characters in contributor names.
However, on Windows you might need to do a bit more: see
L<https://github.com/msysgit/msysgit/wiki/Git-for-Windows-Unicode-Support> for
supported versions and extra configurations you may need to apply.

=head1 SUPPORT

=for stopwords irc

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Git-Contributors>
(or L<bug-Dist-Zilla-Plugin-Git-Contributors@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Git-Contributors@rt.cpan.org>).
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 SEE ALSO

=for :list
* L<How I'm using Dist::Zilla to give credit to contributors|http://www.dagolden.com/index.php/1921/how-im-using-distzilla-to-give-credit-to-contributors/>
* L<Pod::Weaver::Section::Contributors>
* L<Dist::Zilla::Plugin::Meta::Contributors>
* L<Dist::Zilla::Plugin::ContributorsFile>
* L<Dist::Zilla::Plugin::ContributorsFromGit>
* L<Dist::Zilla::Plugin::ContributorsFromPod>
* L<Module::Install::Contributors>

=for Pod::Coverage metadata

=cut
