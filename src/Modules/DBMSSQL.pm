package DBMSSQL;

use 5.010;
use Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(dbmssqlAnalize);


sub dbmssqlAnalize {

    die('Недостаточно аргументов') if (@_ < 4);
    die('Излишнее количество аргументов') if (@_ > 4);

    my ($head, $root_dir,$glob_exp, $res_filename) = @_;
    my $multiline = 0;
    my $context_processing = 0;
    my $dur = 0;
    my $key = "";
    my %counting = ();
    my %duration = ();
    my @glob_arg;

    chdir $root_dir or die "Ошибка обнаружения корневой директории искомых файлов: $!";
    @glob_arg = glob ($glob_exp) or die "Ошибка поиска файлов по заданному шаблону: $!";

    open(my $res_file, '>:encoding(UTF-8)', $res_filename)
                or die "Could not open result file '$res_file' $!";

    if(@glob_arg > 0){
        foreach $filename (@glob_arg) {
            
            open(my $file, '<:encoding(UTF-8)', $filename)
                or die "Could not open file '$filename' $!";
            
            while (my $row = <$file>) {
                #print "$row \n------------------\n"; 
                #print index ($row,"DBMSSQL") . "\n";
                if(index ($row,",DBMSSQL") != -1){
                    $context_processing = 0;

                    $dur = $row =~ m!^\d{2}:\d{2}\.\d{6}-(\d+)! ? $1 : 0;
                    
                    #print $row . "\n";
                    given($row)
                    {
                        
                        when($_ ~~ /Context=([^'].+?),/ && $multiline == 0){

                            print "DURATION $dur \n";
                            $key = $1;
                            chomp($key);
                            $duration{$key} = $dur + ($duration{$key} = undef ? 0: $duration{$key}); 
                            $counting{$key} = 1 + ($counting{$key} = undef ? 0: $counting{$key});
                            
                            #print $duration{$key};
                            $dur = 0;
                            $multiline = 0;
                            $context_processing = 0;
                            $key = "";
                        }
                        when($_ ~~ /Context='/ && $multiline == 0){

                            $multiline = 1;
                            $context_processing = 1;
                           
                            if($row =~ m!Context='[А-яA-z]+!){
                                print "$_ \n------------------\n";
                                my $ind = index($row,"'",index($row, "Context='"));
                                #print $ind;
                                my $lenght = length $row;
                                $key = ($ind == -1 ? '': substr($row, $ind + 1, $lenght - 1));
                                chomp($key);
                            
                            }else{$key = ""};
                            
                            #print "$key \n------------------\n";
                            #print "$key \n";
                            #chomp($key);
                            
                            
                         }
                         
                    }
                     
                }elsif($multiline == 1 && $context_processing == 1){
                             
                            #print "$key \n";
                            
                            #print "$row \n------------------\n";
                            
                            my $ind_close = index($row,"'");
                            if($ind_close != -1){

                                    my $lenght = length $row;

                                    #print substr($row, 1,$ind_close - 1);
                                    #print "$key \n------------------\n";
                                    #print "ROW $row \n------------------\n";
                                    
                                    my $con_key = substr($row, 1,$ind_close - 1);
                                    $con_key =~ s![\s]!!g;
                                    #print "CON $con_key \n------------------\n";
                                    $key = $key . $con_key;
                                    chomp($key);
                                    #print "KEY $key \n------------------\n";
                                   
                                    $duration{$key} = $dur + ($duration{$key} = undef ? 0: $duration{$key});
                                    $counting{$key} = 1 + ($counting{$key} = undef ? 0: $counting{$key});
                                    
                                    $multiline = 0;
                                    $context_processing = 0;
                                    $dur = 0;
                            }else{$row =~ s![\s]!!g; $key = $key . $row}
                            
                         }
            
            }
            close $filename;
        }
    my $ind = 0;
    for my $key (sort { $duration{$b} / $counting{$b} <=> $duration{$a} / $counting{$a} } keys %duration) {
        if($head > 0 && $ind > $head){last};
        my $aver = sprintf "%.2f", $duration{$key} / $counting{$key};
        print $res_file "$aver ### $counting{$key} ### $key\n";
        $ind ++;
    }
    close $res_file;

    }else{print "Не удалось найти файлы по заданному шаблону"}
}

return 1;