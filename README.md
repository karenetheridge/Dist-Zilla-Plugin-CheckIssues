# NAME

Dist::Zilla::Plugin::CheckIssues - Retrieve count of outstanding RT and github issues

# VERSION

version 0.001

# SYNOPSIS

In your `dist.ini`:

    [CheckIssues]
    rt = 1              ; default
    github = 1          ; default
    colour = 1          ; default

    [ConfirmRelease]

# DESCRIPTION

This is a [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) plugin that retrieves the RT and/or github issue
counts for your distribution before release.  Place it immediately before
`[ConfirmRelease]` in your `dist.ini` to give you an opportunity to abort the
release if you forgot to fix a bug or merge a pull request.

# CONFIGURATION OPTIONS

## `rt`

Checks your distribution's queue at [https://rt.cpan.org/](https://rt.cpan.org/). Defaults to true.
(You should leave this enabled even if you have your main issue list on github,
as sometimes tickets still end up on RT.)

## `github`

Checks the issue list on [github](https://github.com) for your distribution; does
nothing if your distribution is not hosted on [github](https://github.com), as
listed in your distribution's metadata.  Defaults to true.

(Not yet implemented. Coming soon!)

## `color` or `colour`

Uses [Term::ANSIColor](https://metacpan.org/pod/Term::ANSIColor) to colour-code the results according to severity.
Defaults to true.

# FUTURE FEATURES, MAYBE

If I can find the right APIs to call, it would be nice to have a `verbose`
option which fetches the actual titles of the open issues. Advice or patches welcome!

Possibly other issue trackers? Does anyone even use any other issue trackers
anymore? :)

# SUPPORT

Bugs may be submitted through [the RT bug tracker](https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-CheckIssues)
(or [bug-Dist-Zilla-Plugin-CheckIssues@rt.cpan.org](mailto:bug-Dist-Zilla-Plugin-CheckIssues@rt.cpan.org)).
I am also usually active on irc, as 'ether' at `irc.perl.org`.

# ACKNOWLEDGEMENTS

Some code was liberally stolen from Ricardo Signes's
[codereview tool](https://github.com/rjbs/misc/blob/master/code-review).

# SEE ALSO

- [foo](https://metacpan.org/pod/foo)

# AUTHOR

Karen Etheridge <ether@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
