#use warnings;
use strict;
use 5.010;
use Cwd qw();
use Benchmark;
#use DateTime;

use lib (Cwd::cwd() . "/Modules/");
use CALL;
#use CALL_Optimized;
use DBMSSQL;

die('Излишнее количество аргументов') if (@ARGV > 5);

my $t0 = Benchmark->new;

my ($event, $head, $root_dir, $glob_exp) = @ARGV;

my $ucEvent = uc($event);

my $res_filename = $ucEvent . " " .localtime() . ".txt";

given($ucEvent)
{
    when('DBMSSQL'){&dbmssqlAnalize($head, $root_dir, $glob_exp, $res_filename)}
    when('CALL'){&callAnalize($head, $root_dir, $glob_exp, $res_filename)}
    when('CALL_CPUTIME'){&cputimeAnalyze($head, $root_dir, $glob_exp, $res_filename)}  
    when('CALL_MEMORYUSE'){&MemoryUseAnalize($head, $root_dir, $glob_exp, $res_filename)}  
    default {print "Какое то событие $ucEvent"}
}

my $t1 = Benchmark->new;

print "the code took:" ,timestr(timediff($t1, $t0)),"\n";
