use strict;
use warnings;
package Dist::Zilla::App::Command::issues;
# ABSTRACT: Print the count of outstanding RT and github issues for your distribution
# vim: set ts=8 sts=4 sw=4 tw=115 et :

our $VERSION = '0.009';

use Dist::Zilla::App -command;

sub abstract { "print your distribution's count of outstanding RT and github issues" }

sub opt_spec
{
    [ 'all!' => 'check both RT and github, regardless of plugin configuration' ],
    [ 'rt!'  => 'get RT information', { default => 1 } ],
    [ 'github!' => 'get github information', { default => 1 } ],
    [ 'colour|color!' => 'Uses L<Term::ANSIColor> to colour-code the results according to severity', { default => 1 } ],
    [ 'repo=s' => 'URL of the github repository' ],
}

sub execute
{
    my ($self, $opt) = @_; # $arg

    $self->app->chrome->logger->mute unless $self->app->global_options->verbose;

    # parse dist.ini and load, instantiate all plugins
    my $zilla = $self->zilla;

    my @plugins = grep { $_->isa('Dist::Zilla::Plugin::CheckIssues') } @{ $zilla->plugins };
    if (not @plugins)
    {
        require Dist::Zilla::Plugin::CheckIssues;
        push @plugins,
            Dist::Zilla::Plugin::CheckIssues->new(
                zilla => $zilla,
                plugin_name => 'issues_command',
                rt => ($opt->all || $opt->rt ? 1 : 0),
                github => ($opt->all || $opt->github ? 1 : 0),
                colour => $opt->colour,
            );
    }

    $plugins[0]->repo_url($opt->repo) if $opt->repo;

    my @issues = $plugins[0]->get_issues;

    $self->app->chrome->logger->unmute;
    $self->log($_) foreach @issues;
}

1;
__END__

=pod

=head1 SYNOPSIS

  $ dzil issues

=head1 DESCRIPTION

This is a command plugin for L<Dist::Zilla>. It provides the C<issues> command,
which acts as L<[CheckIssues|Dist::Zilla::Plugin::CheckIssues> would
during the build: prints the RT and/or github issue counts for your distribution.

=head1 OPTIONS

If you have C<[CheckIssues]> in your F<dist.ini>, its configuration is used
(with the exception of C<repo> which is always valid).
Otherwise, the command-line options come into play:

=head2 --rt

Checks your distribution's queue at L<https://rt.cpan.org/>. Defaults to true.
(You should leave this enabled even if you have your main issue list on github,
as sometimes tickets still end up on RT.)

=head2 --github

Checks the issue list on L<github|https://github.com> for your distribution; does
nothing if your distribution is not hosted on L<github|https://github.com>, as
listed in your distribution's metadata.  Defaults to true.

=head2 --all

Same as --rt --github

=head2 --colour or --color

Uses L<Term::ANSIColor> to colour-code the results according to severity.
Defaults to true.

=head2 --repo <string>

The URL of the github repository.  This is normally fetched from the
C<resources> field in metadata, but can be explicitly passed if your
distribution's plugins cannot yet determine the repository location (for
example you haven't configured the git remote spec).

=head1 SUPPORT

=for stopwords irc

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-CheckIssues>
(or L<bug-Dist-Zilla-Plugin-CheckIssues@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-CheckIssues@rt.cpan.org>).
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 SEE ALSO

=for :list
* L<Dist::Zilla::Plugin::CheckIssues>

=cut
