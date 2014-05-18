use strict;
use warnings FATAL => 'all';

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Test::Deep;
use Path::Tiny;
use Moose::Util 'find_meta';

use lib 't/lib';
use NoNetworkHits;

# data copied from Moose stats
my $rt_text = '{"Foo-Bar":{"dist":"Foo-Bar","counts":{"rejected":0,"inactive":1,"active":0,"resolved":1,"patched":0,"open":0,"stalled":0,"new":0}},"DZT-Sample":{"dist":"DZT-Sample","counts":{"rejected":47,"inactive":207,"active":52,"resolved":160,"patched":0,"deleted":108,"open":39,"stalled":4,"new":9}}}';

{
    use Dist::Zilla::Plugin::CheckIssues;
    my $meta = find_meta('Dist::Zilla::Plugin::CheckIssues');
    $meta->make_mutable;
    $meta->add_around_method_modifier(_rt_data_raw => sub { $rt_text });
    $meta->add_around_method_modifier(_github_issue_count => sub { 3 });
}

my $tzil = Builder->from_config(
    { dist_root => 't/does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MetaResources => { 'repository.url' => 'git://github.com/dude/project.git' } ],
                [ CheckIssues => { colour => 0 } ],
                [ FakeRelease => ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->release },
    undef,
    'release proceeds normally',
) or diag 'saw log messages: ', explain $tzil->log_messages;

cmp_deeply(
    [ map { split "\n" } @{ $tzil->log_messages } ],
    superbagof(
        '[CheckIssues] Issues on RT (https://rt.cpan.org/Public/Dist/Display.html?Name=DZT-Sample):',
        '[CheckIssues]   open: 48   stalled: 4',
        '[CheckIssues] Issues on github (https://github.com/dude/project):',
        '[CheckIssues]   open: 3',
    ),
    'bug information correctly printed',
) or diag 'saw log messages: ', explain $tzil->log_messages;

done_testing;
