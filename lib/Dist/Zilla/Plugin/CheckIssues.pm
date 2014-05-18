use strict;
use warnings;
package Dist::Zilla::Plugin::CheckIssues;
# ABSTRACT: Retrieve count of outstanding RT and github issues
# vim: set ts=8 sw=4 tw=78 et :

use Moose;
with 'Dist::Zilla::Role::BeforeRelease';
use HTTP::Tiny;
use JSON::MaybeXS;
use Term::ANSIColor 'colored';
use namespace::autoclean;

has [qw(rt github colour)] => (
    is => 'ro', isa => 'Bool',
    default => 1,
);

# [ user/org name, repo name ]
has _github_repository => (
    isa => 'ArrayRef[Str]',
    lazy => 1,
    default => sub {
        my $self = shift;

        my $distmeta = $self->zilla->distmeta;
        my $url = (($distmeta->{resources} || {})->{repository} || {})->{url} || '';

        my ($org_name, $repo_name) = $url =~ m{github\.com/([^/]+)/([^/]+?)(?:/|\.git|$)};

        return [ $org_name, $repo_name ] if $org_name and $repo_name;

        $self->log('failed to find a github repo in metadata');
        [];
    },
    traits => ['Array'],
    handles => { _github_repository => 'elements' },
);

has repo_url => (
    is => 'ro', isa => 'Str',
    lazy => 1,
    default => sub {
        my $self = shift;
        my ($org_name, $repo_name) = $self->_github_repository;
        return "https://github.com/$org_name/$repo_name" if $org_name and $repo_name;
        '';
    },
);

sub mvp_aliases { +{ color => 'colour' } }

sub before_release
{
    my $self = shift;

    my $dist_name = $self->zilla->name;

    if ($self->rt)
    {
        my %rt_data = $self->_rt_data_for_dist($dist_name);

        my $colour = $rt_data{open} ? 'red'
            : $rt_data{stalled} ? 'yellow'
            : 'green';

        my $text = 'Issues on RT (https://rt.cpan.org/Public/Dist/Display.html?Name='
            . $dist_name . '):' . "\n"
            . 'open: ' .  ($rt_data{open} || 0)
            . '   stalled: ' . ($rt_data{stalled} || 0);

        $text = colored($text, $colour) if $self->colour;
        $self->log($text);
    }

    if ($self->github
        and my ($owner_name, $repo_name) = $self->_github_repository)
    {
        my $issue_count = $self->_github_issue_count($owner_name, $repo_name);
        if (defined $issue_count)
        {
            my $colour = $issue_count ? 'red' : 'green';

            my $text = 'Issues on github (' . $self->repo_url . "):\nopen: " . $issue_count;

            $text = colored($text, $colour) if $self->colour;
            $self->log($text);
        }
    }

    return;
}

sub _rt_data_for_dist
{
    my ($self, $dist_name) = @_;

    my $json = $self->_rt_data_raw;
    return if not $json;

    my $all_data = decode_json($json);
    return if not $all_data->{$dist_name};

    my %rt_data;
    $rt_data{open} = $all_data->{$dist_name}{counts}{active}
                   - $all_data->{$dist_name}{counts}{stalled};
    $rt_data{stalled} = $all_data->{$dist_name}{counts}{stalled};
    return %rt_data;
}

sub _rt_data_raw
{
    my $self = shift;

    $self->log_debug('fetching RT bug data...');
    my $res = HTTP::Tiny->new->get('https://rt.cpan.org/Public/bugs-per-dist.json');
    $self->log('could not fetch RT data?'), return if not $res->{success};
    return $res->{content};
}

sub _github_issue_count
{
    my ($self, $owner_name, $repo_name) = @_;

    $self->log_debug('fetching github issues data...');
    my $res = HTTP::Tiny->new->get('https://api.github.com/repos/' . $owner_name . '/' . $repo_name);
    $self->log('could not fetch github data?'), return if not $res->{success};
    my $json = $res->{content};

    my $data = decode_json($json);
    $data->{open_issues_count};
}

__PACKAGE__->meta->make_immutable;
__END__

=pod

=head1 SYNOPSIS

In your F<dist.ini>:

    [CheckIssues]
    rt = 1              ; default
    github = 1          ; default
    colour = 1          ; default

    [ConfirmRelease]

=head1 DESCRIPTION

This is a L<Dist::Zilla> plugin that retrieves the RT and/or github issue
counts for your distribution before release.  Place it immediately before
C<[ConfirmRelease]> in your F<dist.ini> to give you an opportunity to abort the
release if you forgot to fix a bug or merge a pull request.

=for Pod::Coverage mvp_aliases before_release

=head1 CONFIGURATION OPTIONS

=head2 C<rt>

Checks your distribution's queue at L<https://rt.cpan.org/>. Defaults to true.
(You should leave this enabled even if you have your main issue list on github,
as sometimes tickets still end up on RT.)

=head2 C<github>

Checks the issue list on L<github|https://github.com> for your distribution; does
nothing if your distribution is not hosted on L<github|https://github.com>, as
listed in your distribution's metadata.  Defaults to true.

(Not yet implemented. Coming soon!)

=head2 C<color> or C<colour>

Uses L<Term::ANSIColor> to colour-code the results according to severity.
Defaults to true.

=head1 FUTURE FEATURES, MAYBE

If I can find the right APIs to call, it would be nice to have a C<verbose>
option which fetches the actual titles of the open issues. Advice or patches welcome!

Possibly other issue trackers? Does anyone even use any other issue trackers
anymore? :)

=head1 SUPPORT

=for stopwords irc

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-CheckIssues>
(or L<bug-Dist-Zilla-Plugin-CheckIssues@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-CheckIssues@rt.cpan.org>).
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 ACKNOWLEDGEMENTS

=for stopwords Ricardo Signes codereview

Some code was liberally stolen from Ricardo Signes's
L<codereview tool|https://github.com/rjbs/misc/blob/master/code-review>.

=head1 SEE ALSO

=begin :list

* L<foo>

=end :list

=cut
