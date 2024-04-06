#use warnings;
use strict;
use 5.010;
use Cwd qw();
use Benchmark;

use lib (Cwd::cwd() . "/Modules/");
use CALL;
use DBMSSQL;

die('Излишнее количество аргументов') if (@ARGV > 5);

my $t0 = Benchmark->new;

my ($event, $head, $res_filename, $root_dir, $glob_exp) = @ARGV;

given( $event )
{
    when('DBMSSQL'){&dbmssqlAnalize($head, $root_dir, $glob_exp, $res_filename)}
    when('CALL'){&callAnalize($head, $root_dir, $glob_exp, $res_filename)}    
    default {print "Какое то событие $event"}
}

my $t1 = Benchmark->new;

print "the code took:" ,timestr(timediff($t1, $t0)),"\n";
