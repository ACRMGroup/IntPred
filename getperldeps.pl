#!/usr/bin/env perl
use Module::Build;
my @deps = qw(
Test::Class::Moose
Config::IniFiles
MooseX:Aliases
);
# Currently installed with versions specified - this can be
# changed in the future if needs be
my $build = Module::Build->new(
    module_name => 'IntPred',
    requires => {map {$_ => 0} @deps},
    );
$build->dispatch('installdeps');
