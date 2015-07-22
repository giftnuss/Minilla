package Minilla::ModuleMaker::ExtUtilsMakeMaker;
use strict;
use warnings;
use utf8;
use Data::Section::Simple qw(get_data_section);
use Text::MicroTemplate qw(render_mt);
use Data::Dumper;
use File::Spec::Functions qw(catdir rel2abs);
use File::Find ();
use TAP::Harness::Env;

# This module is EXPERIMENTAL.
# You can use this. But I may change the behaviour...

use Moo;

no Moo;

use Minilla::Util qw(spew_raw);

sub generate {
    my ($self, $project) = @_;

    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Useqq = 1;
    local $Data::Dumper::Purity = 1;
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Sortkeys = 1;
    my $content = get_data_section('Makefile.PL');
    my $mt = Text::MicroTemplate->new(template => $content, escape_func => sub { $_[0] });
    my $src = $mt->build->($project);
    spew_raw('Makefile.PL', $src);
}

sub prereqs {
    my ($self, $project) = @_;

    my %configure_requires = (
        'ExtUtils::MakeMaker' => '6.64', # TEST_REQUIRES (and MYMETA)
    );

    my $prereqs = +{
        configure => {
            requires => {
                %configure_requires,
            }
        }
    };

    for my $key (qw(tap_harness_args use_xsutil c_source allow_pureperl requires_external_bin)) {
        if( $project->$key ){
            die "$key does not supported by " . __PACKAGE__;
        }
    }
    return $prereqs;
}

sub run_tests {
    my $harness = TAP::Harness::Env->create({
        verbosity => 0,
        lib       => [ map { rel2abs(catdir(qw/blib/, $_)) } qw/arch lib/ ],
        color     => -t STDOUT
    });
    my @tests = sort +_find(qr/\.t$/, 't');
    if ($ENV{RELEASE_TESTING}) {
        push @tests, sort +_find(qr/\.t$/, 'xt');
    }
    $harness->runtests(@tests)->has_errors and die;
}

sub _find {
    my ($pattern, $dir) = @_;
    my @ret;
    File::Find::find(sub { push @ret, $File::Find::name if /$pattern/ && -f }, $dir) if -d $dir;
    return @ret;
}

1;
__DATA__

@@ Makefile.PL
? my $project = shift;
? use Data::Dumper;
# =========================================================================
# THIS FILE IS AUTOMATICALLY GENERATED BY MINILLA.
# DO NOT EDIT DIRECTLY.
# =========================================================================

use 5.006;
use strict;

use ExtUtils::MakeMaker 6.64;

? if ( @{ $project->requires_external_bin || [] } ) {
use Devel::CheckBin;

?   for my $bin ( @{ $project->requires_external_bin } ) {
check_bin('<?= $bin ?>');
?   }

? }

? my $prereqs = $project->cpan_meta->effective_prereqs;
? my $d = sub { Dumper($prereqs->merged_requirements([$_[0]], ['requires'])->as_string_hash) };
my %WriteMakefileArgs = (
    NAME     => '<?= $project->name ?>',
    DISTNAME => '<?= $project->dist_name ?>',
    VERSION  => '<?= $project->version ?>',
    EXE_FILES => [<?= $project->script_files ?>],
    CONFIGURE_REQUIRES => <?= $d->('configure') ?>,
    BUILD_REQUIRES     => <?= $d->('build') ?>,
    TEST_REQUIRES      => <?= $d->('test') ?>,
    PREREQ_PM          => <?= $d->('runtime') ?>,
);

WriteMakefile(%WriteMakefileArgs);
