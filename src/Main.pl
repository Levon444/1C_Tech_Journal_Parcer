#use warnings;
use strict;
use 5.010;
use Cwd qw();
use Benchmark;
#use DateTime;

use lib (Cwd::cwd() . "/Modules/");
use CALL;
#use CALL_Optimized;
use LOCK;
use DBMSSQL;

die('Излишнее количество аргументов') if (@ARGV > 5);

print Cwd::getcwd();

my $t0 = Benchmark->new;

my ($event, $head, $root_dir, $glob_exp) = @ARGV;

my $ucEvent = uc($event);

my $res_dir = Cwd::getcwd() . "/" . "Results/";
my $res_filename =  $res_dir . $ucEvent . " " .localtime() . ".txt";

given($ucEvent)
{
    when('DBMSSQL'){&dbmssqlAnalize($head, $root_dir, $glob_exp, $res_filename, $res_dir)}
    when('CALL'){&callAnalize($head, $root_dir, $glob_exp, $res_filename, $res_dir)}
    when('CALL_CPUTIME'){&cputimeAnalyze($head, $root_dir, $glob_exp, $res_filename, $res_dir)}  
    when('CALL_MEMORYUSE'){&MemoryUseAnalize($head, $root_dir, $glob_exp, $res_filename, $res_dir)}  
    when('LOCK'){&lockAnalize($head, $root_dir, $glob_exp, $res_filename, $res_dir)}
    default {print "Какое то событие $ucEvent"}
}

my $t1 = Benchmark->new;

print "the code took:" ,timestr(timediff($t1, $t0)),"\n";
