package Minilla::ModuleMaker::ModuleBuild;
use strict;
use warnings;
use utf8;
use Data::Section::Simple qw(get_data_section);
use Text::MicroTemplate qw(render_mt);
use Data::Dumper;
use Minilla::Util qw(cmd_perl);

use Moo;

no Moo;

use Minilla::Util qw(spew_raw);

sub generate {
    my ($self, $project) = @_;

    Carp::croak('Usage: $module_maker->generate($project)') unless defined $project;

    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Useqq = 1;
    local $Data::Dumper::Purity = 1;
    local $Data::Dumper::Indent = 0;
    my $content = get_data_section('Build.PL');
    my $mt = Text::MicroTemplate->new(template => $content, escape_func => sub { $_[0] });
    my $src = $mt->build->($project);
    spew_raw('Build.PL', $src);
}

sub prereqs {
    my ($self, $project) = @_;

    Carp::croak('Usage: $module_maker->prereqs($project)') unless defined $project;

    my %configure_requires = (
        'Module::Build'       => 0.4005, # test_requires, --pureperl
    );
    if ($project->requires_external_bin && @{$project->requires_external_bin}) {
        $configure_requires{'Devel::CheckBin'} = 0;
    }

    my $prereqs = +{
        configure => {
            requires => {
                %configure_requires,
            }
        }
    };

    if( $project->use_xsutil ){
        $prereqs->{configure}{requires}{'Module::Build::XSUtil'} = '0.03';
    }
    return $prereqs;
}

sub run_tests {
    cmd_perl('Build', 'test');
}

1;
__DATA__

@@ Build.PL
? my $project = shift;
? use Data::Dumper;
# =========================================================================
# THIS FILE IS AUTOMATICALLY GENERATED BY MINILLA.
# DO NOT EDIT DIRECTLY.
# =========================================================================

use 5.008_001;

use strict;
use warnings;
use utf8;

? if ( $project->build_class !~ m/^Module::Build(?:::XSUtil)?$/ ) {
BEGIN { push @INC, '.' }
? }
use <?= $project->build_class ?>;
use File::Basename;
use File::Spec;

? if ( @{ $project->requires_external_bin || [] } ) {
use Devel::CheckBin;

?   for my $bin ( @{ $project->requires_external_bin } ) {
check_bin('<?= $bin ?>');
?   }

? }
my %args = (
    license              => '<?= $project->metadata->license->meta2_name ?>',
    dynamic_config       => 0,

    configure_requires => {
        'Module::Build' => '0.4005',
    },

    requires => {
?       for my $requirement ( sort keys %{ $project->cpan_meta->prereqs->{runtime}{requires} } ){
        '<?= $requirement ?>' => '<?= $project->cpan_meta->prereqs->{runtime}{requires}{$requirement} ?>',
?       }
    },

    recommends => {
?       for my $recommendation ( sort keys %{ $project->cpan_meta->prereqs->{runtime}{recommends} } ){
        '<?= $recommendation ?>' => '<?= $project->cpan_meta->prereqs->{runtime}{recommends}{$recommendation} ?>',
?       }
    },

    suggests => {
?       for my $suggestion ( sort keys %{ $project->cpan_meta->prereqs->{runtime}{suggests} } ){
        '<?= $suggestion ?>' => '<?= $project->cpan_meta->prereqs->{runtime}{suggests}{$suggestion} ?>',
?       }
    },

    build_requires => {
?       for my $requirement ( sort keys %{ $project->cpan_meta->prereqs->{build}{requires} } ){
        '<?= $requirement ?>' => '<?= $project->cpan_meta->prereqs->{build}{requires}{$requirement} ?>',
?       }
    },

    test_requires => {
?       for my $requirement ( sort keys %{ $project->cpan_meta->prereqs->{test}{requires} } ){
        '<?= $requirement ?>' => '<?= $project->cpan_meta->prereqs->{test}{requires}{$requirement} ?>',
?       }
    },

    name            => '<?= $project->dist_name ?>',
    module_name     => '<?= $project->name ?>',
    allow_pureperl => <?= $project->allow_pureperl ?>,

    script_files => [<?= $project->script_files ?>],
? if ($project->c_source) {
    c_source     => [qw(<?= $project->c_source ?>)],
? }
    PL_files => <?= Data::Dumper::Dumper($project->PL_files) ?>,

    test_files           => ((-d '.git' || $ENV{RELEASE_TESTING}) && -d 'xt') ? 't/ xt/' : 't/',
    recursive_test_files => 1,

? if( $project->tap_harness_args ){
    tap_harness_args => <?= Dumper($project->tap_harness_args) ?>,
? }

? if( $project->use_xsutil ){
    needs_compiler_c99 => <?= $project->needs_compiler_c99 ?>,
    needs_compiler_cpp => <?= $project->needs_compiler_cpp ?>,
    generate_ppport_h => '<?= $project->generate_ppport_h ?>',
    generate_xshelper_h => '<?= $project->generate_xshelper_h ?>',
    cc_warnings => <?= $project->cc_warnings ?>,
? }
);
if (-d 'share') {
    $args{share_dir} = 'share';
}

my $builder = <?= $project->build_class ?>->subclass(
    class => 'MyBuilder',
    code => q{
        sub ACTION_distmeta {
            die "Do not run distmeta. Install Minilla and `minil install` instead.\n";
        }
        sub ACTION_installdeps {
            die "Do not run installdeps. Run `cpanm --installdeps .` instead.\n";
        }
    }
)->new(%args);
$builder->create_build_script();

