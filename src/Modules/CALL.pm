package CALL;

use 5.010;
use Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(callAnalize cputimeAnalyze MemoryUseAnalize);


sub callAnalize {

    die('Недостаточно аргументов') if (@_ < 4);
    die('Излишнее количество аргументов') if (@_ > 4);

    my ($head, $root_dir,$glob_exp, $res_filename) = @_;
    my $multiline;
    my $dur = 0;
    my $key = "";
    my %counting = ();
    my %duration = ();
    my @glob_arg;

    chdir $root_dir or die "Ошибка обнаружения корневой директории искомых файлов: $!";
    @glob_arg = glob ($glob_exp) or die "Ошибка поиска файлов по заданному шаблону: $!";

    open(my $res_file, '>', $res_filename)
                or die "Could not open result file '$res_file' $!";

    if(@glob_arg > 0){
        foreach $filename (@glob_arg) {
            
            open(my $file, '<', $filename)
                or die "Could not open file '$filename' $!";
            
            while (my $row = <$file>) {
                #print "$row \n------------------\n"; 
                if($row =~ m!,CALL,.+,Context=.+!){
                    $dur = $row =~ m!^\d{2}:\d{2}\.\d{6}-(\d+)! ? $1 : 0;
                    #print $row;
                    given($row)
                    {
                        
                        when($_ ~~ /Context=([^'].+?),/ && $multiline == 0){

                            #print "DURATION $dur \n";
                            $key = $1;
                            chomp($key);
                            $duration{$key} = $dur + ($duration{$key} = undef ? 0: $duration{$key}); 
                            $counting{$key} = 1 + ($counting{$key} = undef ? 0: $counting{$key});
                            
                            #print $duration{$key};
                            $dur = 0;
                            $multiline = 0;
                            $key = "";
                        }
                        when($_ ~~ /Context='/ && $multiline == 0){

                            #print "$filename multiline $row \n------------------\n";

                            #print "$_ \n------------------\n";
                            my $ind = index($row,"'");
                            #print $ind;
                            my $lenght = length $row;
                            $key = ($ind == -1 ? '': substr($row, $ind + 1, $lenght - 1));
                            #print "$key \n------------------\n";
                            #print "$key \n";
                            chomp($key);
                            $multiline = 1;
                         }
                         
                    }
                     
                }elsif($multiline == 1){
                             
                            #print "$key \n";
                            
                            
                            
                            my $ind_close = index($row,"'");
                            if($ind_close != -1){

                                    my $lenght = length $row;

                                    #print substr($row, 1,$ind_close - 1);
                                    #print "$key \n------------------\n";
                                    #print "ROW $row \n------------------\n";
                                    
                                    my $con_key = substr($row, 1,$ind_close - 1);
                                    $con_key =~ s![\s]!!g;
                                    #chomp($con_key);
                                    #print "CON $con_key \n------------------\n";
                                    $key = $key . $con_key;
                                    chomp($key);
                                    #print "KEY $key \n------------------\n";
                                    $multiline = 0;
                                    $duration{$key} = $dur + ($duration{$key} = undef ? 0: $duration{$key});
                                    $counting{$key} = 1 + ($counting{$key} = undef ? 0: $counting{$key});
                                    $dur = 0;
                            }else{$row =~ s![\s]!!g; $key = $key . $row}
                            
                         }
            
            }
            close $filename;
        }
    my $ind = 0;
    print $res_file "AVERAGE\tCOUNT\tCONTEXT\n";
    for my $key (sort { $duration{$b} / $counting{$b} <=> $duration{$a} / $counting{$a} } keys %duration) {
        if($head > 0 && $ind > $head){last};
        my $aver = sprintf "%.2f", $duration{$key} / $counting{$key};
        print $res_file "$aver\t$counting{$key}\t$key\n";
        $ind ++;
    }
    close $res_file;

    }else{print "Не удалось найти файлы по заданному шаблону"}
}


sub cputimeAnalyze {

    die('Недостаточно аргументов') if (@_ < 4);
    die('Излишнее количество аргументов') if (@_ > 4);

    my ($head, $root_dir,$glob_exp, $res_filename) = @_;
    my $multiline = 0; my $dur = 0; my $key = "";
    my %counting = (); my %cputime_sum = (); my %cputime_max = (); my %duration = ();
    my @glob_arg;

    chdir $root_dir or die "Ошибка обнаружения корневой директории искомых файлов: $!";
    @glob_arg = glob ($glob_exp) or die "Ошибка поиска файлов по заданному шаблону: $!";

    open(my $res_file, '>', $res_filename)
                or die "Could not open result file '$res_file' $!";

    if(@glob_arg > 0){
        foreach $filename (@glob_arg) {
            
            open(my $file, '<', $filename)
                or die "Could not open file '$filename' $!";
            
            while (my $row = <$file>) {
                #print "$row \n------------------\n"; 
                if($row =~ m!,CALL,.+,Context=.+!){
                    $dur = $row =~ m!^\d{2}:\d{2}\.\d{6}-(\d+)! ? $1 : 0;
                    #print $row;
                    given($row)
                    {
                        
                        when($_ ~~ /Context=([^'].+?),/ && $multiline == 0){

                            #print "DURATION $dur \n";
                            $key = $1;
                            chomp($key);
                            $duration{$key} = $dur + ($duration{$key} == undef ? 0: $duration{$key}); 
                            $counting{$key} = 1 + ($counting{$key} == undef ? 0: $counting{$key});
                            
                            if($_ ~~ /CpuTime=(\d+)/) {
                                $cputime_sum{$key} = $1 + ($cputime_sum{$key} == undef ? 0: $cputime_sum{$key});
                                if ($1 > ($cputime_max{$key} == undef ? 0: $cputime_max{$key}) && $1 != 0) {
                                            $cputime_max{$key} = $1
                                };
                            }
                            #print $duration{$key};
                            $dur = 0;
                            $multiline = 0;
                            $key = "";
                        }
                        when($_ ~~ /Context='/ && $multiline == 0){

                            #print "$filename multiline $row \n------------------\n";

                            #print "$_ \n------------------\n";
                            my $ind = index($row,"'");
                            #print $ind;
                            my $lenght = length $row;
                            $key = ($ind == -1 ? '': substr($row, $ind + 1, $lenght - 1));
                            #print "$key \n------------------\n";
                            #print "$key \n";
                            chomp($key);
                            $multiline = 1;
                        }
                         
                    }
                     
                }elsif($multiline == 1){
                             
                            #print "$key \n";
                            
                            
                            
                            my $ind_close = index($row,"'");
                            if($ind_close != -1){

                                    my $lenght = length $row;

                                    #print substr($row, 1,$ind_close - 1);
                                    #print "$key \n------------------\n";
                                    #print "ROW $row \n------------------\n";
                                    
                                    my $con_key = substr($row, 1,$ind_close - 1);
                                    $con_key =~ s![\s]!!g;
                                    #chomp($con_key);
                                    #print "CON $con_key \n------------------\n";
                                    $key = $key . $con_key;
                                    chomp($key);
                                    #print "KEY $key \n------------------\n";
                                    $multiline = 0;
                                    $duration{$key} = $dur + ($duration{$key} == undef ? 0: $duration{$key});
                                    $counting{$key} = 1 + ($counting{$key} == undef ? 0: $counting{$key});

                                    if($_ ~~ /CpuTime=(\d+)/) {
                                        print $1;
                                        $cputime_sum{$key} = $1 + ($cputime_sum{$key} == undef ? 0: $cputime_sum{$key});

                                        if ($1 > ($cputime_max{$key} == undef ? 0: $cputime_max{$key}) && $1 != 0) {
                                            $cputime_max{$key} = $1
                                        };
                                    }
                            
                                    $dur = 0;
                            }else{$row =~ s![\s]!!g; $key = $key . $row}
                            
                         }
            
            }
            close $filename;
        }
    my $ind = 0;
    print $res_file "CPUMAX\tCPUSUM\tAVERAGE EXEC TIME\tCOUNT\tCONTEXT\n";
    for my $key (sort { $cputime_max{$b} <=> $cputime_max{$a} } keys %duration) {
        if($head > 0 && $ind > $head){last};
        my $aver = sprintf "%.2f", $duration{$key} / $counting{$key};
        print $res_file "$cputime_max{$key}\t$cputime_sum{$key}\t$aver\t$counting{$key}\t$key\n";
        $ind ++;
    }
    close $res_file;

    }else{print "Не удалось найти файлы по заданному шаблону"}
}

sub MemoryUseAnalize {

    die('Недостаточно аргументов') if (@_ < 4);
    die('Излишнее количество аргументов') if (@_ > 4);

    my ($head, $root_dir,$glob_exp, $res_filename) = @_;
    my $multiline;
    my $dur = 0;
    my $key = "";
    my %counting = (); my %duration = (); my %memorysum = (); my %memorypeak = ();
    my @glob_arg;

    chdir $root_dir or die "Ошибка обнаружения корневой директории искомых файлов: $!";
    @glob_arg = glob ($glob_exp) or die "Ошибка поиска файлов по заданному шаблону: $!";

    open(my $res_file, '>', $res_filename)
                or die "Could not open result file '$res_file' $!";

    if(@glob_arg > 0){
        foreach $filename (@glob_arg) {
            
            open(my $file, '<', $filename)
                or die "Could not open file '$filename' $!";
            
            while (my $row = <$file>) {
                #print "$row \n------------------\n"; 
                if($row =~ m!,CALL,.+,Context=.+!){
                    $dur = $row =~ m!^\d{2}:\d{2}\.\d{6}-(\d+)! ? $1 : 0;
                    #print $row;
                    given($row)
                    {
                        
                        when($_ ~~ /Context=([^'].+?),/ && $multiline == 0){

                            #print "DURATION $dur \n";
                            $key = $1;
                            chomp($key);
                            $duration{$key} = $dur + ($duration{$key} = undef ? 0: $duration{$key}); 
                            $counting{$key} = 1 + ($counting{$key} = undef ? 0: $counting{$key});
                            
                            if($_ ~~ /,Memory=(\d+),MemoryPeak=(\d+),/){
                                $memorysum{$key} = $1 + ($memorysum{$key} = undef ? 0: $memorysum{$key}) if $1 != 0;  
                                $memorypeak{$key} = $2 if $2 > ($memorypeak{$key} == undef ? 0: $memorypeak{$key}) && $2 != 0;    
                            }
                            #print $duration{$key};
                            $dur = 0;
                            $multiline = 0;
                            $key = "";
                        }
                        when($_ ~~ /Context='/ && $multiline == 0){

                            #print "$filename multiline $row \n------------------\n";

                            #print "$_ \n------------------\n";
                            my $ind = index($row,"'");
                            #print $ind;
                            my $lenght = length $row;
                            $key = ($ind == -1 ? '': substr($row, $ind + 1, $lenght - 1));
                            #print "$key \n------------------\n";
                            #print "$key \n";
                            chomp($key);
                            $multiline = 1;
                         }
                         
                    }
                     
                }elsif($multiline == 1){
                             
                            #print "$key \n";
                            
                            
                            
                            my $ind_close = index($row,"'");
                            if($ind_close != -1){

                                    my $lenght = length $row;

                                    #print substr($row, 1,$ind_close - 1);
                                    #print "$key \n------------------\n";
                                    #print "ROW $row \n------------------\n";
                                    
                                    my $con_key = substr($row, 1,$ind_close - 1);
                                    $con_key =~ s![\s]!!g;
                                    #chomp($con_key);
                                    #print "CON $con_key \n------------------\n";
                                    $key = $key . $con_key;
                                    chomp($key);
                                    #print "KEY $key \n------------------\n";
                                    $multiline = 0;
                                    $duration{$key} = $dur + ($duration{$key} = undef ? 0: $duration{$key});
                                    $counting{$key} = 1 + ($counting{$key} = undef ? 0: $counting{$key});

                                    if($_ ~~ /,Memory=(\d+),MemoryPeak=(\d+),/){
                                        $memorysum{$key} = $1 + ($memorysum{$key} = undef ? 0: $memorysum{$key}) if $1 != 0;  
                                        $memorypeak{$key} = $2 if $2 > ($memorypeak{$key} == undef ? 0: $memorypeak{$key}) && $2 != 0;    
                                    }
                                    $dur = 0;
                            }else{$row =~ s![\s]!!g; $key = $key . $row}
                            
                         }
            
            }
            close $filename;
        }
    my $ind = 0;
    print $res_file "MEMORY SUM\tMEMORY PEAK\tAVERAGE EXEC TIME\tCOUNT\tCONTEXT\n";
    for my $key (sort {$memorysum{$b} <=> $memorysum{$a}} keys %duration) {
        if($head > 0 && $ind > $head){last};
        my $aver = sprintf "%.2f", $duration{$key} / $counting{$key};
        print $res_file "$memorysum{$key}\t$memorypeak{$key}\t$aver\t$counting{$key}\t$key\n";
        $ind ++;
    }
    close $res_file;

    }else{print "Не удалось найти файлы по заданному шаблону"}
}

return 1;