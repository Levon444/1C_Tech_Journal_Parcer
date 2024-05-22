package LOCK;

use 5.010;
use Storable;
use Data::Dumper;
use Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(lockAnalize);

sub lockAnalize{

    my ($head, $root_dir,$glob_exp, $res_filename, $res_dir, $del_tmp) = @_;

    my $excp_filename = &exceptionSearch($head, $root_dir,$glob_exp, $res_dir, 1);
    my $str_lock_files = &lockSearch($head, $root_dir,$glob_exp, $res_dir, 1);

        my @lock_files = split(",", $str_lock_files);

    my $excp_data_ref = retrieve($excp_filename) 
        or die "Could not open file: $excp_filename: $!";

    my $lock_owner_ref = retrieve($lock_files[0]) 
        or die "Could not open file: $!";

    my $lock_victim_ref = retrieve($lock_files[1]) 
        or die "Could not open file: $!";

    my $lock_victim_connid_ref = retrieve($lock_files[2]) 
        or die "Could not open file: $!";

    open(my $res_file, '>', $res_filename)
                or die "Could not open result file '$res_file' $!";

    print $res_file "EVENT\tCONNECTION ID\tSOLIDTIME\tDURATION\tREGION LOCK\tCONTEXT\n";

    foreach my $connID (sort keys %{$excp_data_ref} )  { 
        foreach my $time ( sort keys %{$excp_data_ref -> {$connID}} )  {
            
            my $context = $excp_data_ref -> {$connID} -> {$time};
            print $res_file "EXCP\t$connID\t$time\t$context\n";
            my $owner_found = 0;
                print $res_file "<------------------------------------------------------------------------>\n";
                print $res_file "OWNER TO VICTIM\n";
                print $res_file "<------------------------------------------------------------------------>\n";
                foreach my $time_owner ( sort keys %{$lock_owner_ref -> {$connID}} )  {
                    if($time_owner < $time){
                        foreach my $region (keys %{$lock_owner_ref -> {$connID} -> {$time_owner}} )  {

                            my ($dur_owner, $context_owner) = split(",", $lock_owner_ref -> {$connID} -> {$time_owner}-> {$region});

                            print $res_file "TLOCK OWNER\t$connID\t$time_owner\t$dur_owner\t$region\t$context_owner\n";  

                                     
                                    foreach my $time_victim (sort keys %{$lock_victim_ref -> {$connID}} )  {
                                        
                                        if($time_victim >= $time_owner && $time_victim < $time){
                                            
                                            if (defined($lock_victim_ref -> {$connID} -> {$time_victim} -> {$region}))  {

                                                    my ($dur_victim,$conn_victimID,$context_victim) = split(",",
                                                        $lock_victim_ref -> {$connID} -> {$time_victim} -> {$region});
                                                    
                                                    print $res_file "\tTLOCK VICTIM\t$conn_victimID\t$time_victim\t$dur_victim\t$region\t$context_victim\n";   
                                                
                                            }    
                                        }
                                    }

                                }   
                            }
                    
            
                }

                print $res_file "<------------------------------------------------------------------------>\n";
                print $res_file "VICTIM TO OWNER\n";
                print $res_file "<------------------------------------------------------------------------>\n";

                foreach my $time_victim ( sort keys %{$lock_victim_connid_ref -> {$connID}} )  {
                    if($time_victim < $time){
                        foreach my $region (keys %{$lock_victim_connid_ref -> {$connID} -> {$time_victim}} )  {

                            my ($dur_victim,$wait_victimID,$context_victim) = split(",", 
                                $lock_victim_connid_ref -> {$connID} -> {$time_victim}-> {$region});

                            print $res_file "TLOCK VICTIM\t$connID\t$time_victim\t$dur_victim\t$region\t$context_victim\n";  
                                 
                                    foreach my $time_owner (sort keys %{$lock_owner_ref -> {$wait_victimID}} )  {
                                        
                                        if($time_victim >= $time_owner && $time_owner < $time){
                                            
                                            if (defined($lock_owner_ref -> {$wait_victimID} -> {$time_owner} -> {$region}))  {
                                                    
                                                    

                                                    my ($dur_owner,$context_owner) = split(",",
                                                        $lock_victim_ref -> {$wait_victimID} -> {$time_owner} -> {$region});
                                                    
                                                    print $res_file "\tTLOCK OWNER\t$wait_victimID\t$time_owner\t$dur_owner\t$region\t$context_owner\n";   
                                                
                                            }    
                                        }
                                    }

                                }   
                            }
                    
            
                }

                print $res_file "\n<------------------------------------------------------------------------>\n\n";
        }
    } 
}
    


sub exceptionSearch{

    my ($head, $root_dir,$glob_exp, $res_dir,$is_tmp) = @_;
    
    my $tmp_dir = $res_dir . '/' . 'tmp';
    mkdir $tmp_dir if $is_tmp && ! -d $tmp_dir;

    my $res_filename = ($is_tmp ? $tmp_dir : $res_dir) . "/EXCP";
    $tmp_dir = undef;

    my $eventsearched = 0;
    my $multiline = 0;
    my $connectID = 0;
    my $solidTime = 0;

    my %excp_data;
    my $key = "";
    


    chdir $root_dir or die "Ошибка обнаружения корневой директории искомых файлов: $!";
    my @glob_arg = glob ($glob_exp) or die "Ошибка поиска файлов по заданному шаблону: $!";

    #open(my $res_file, '>', $res_filename)
                #or die "Could not open result file '$res_file' $!";

    if(@glob_arg > 0){
        foreach $filename (@glob_arg) {
            open(my $file, '<', $filename)
                or die "Could not open file '$filename' $!";
            
            while (my $row = <$file>) {
                if($row =~ m!^(\d{2}):(\d{2})\.(\d{6})-\d+,EXCP,.+,t:connectID=(\d+),.+,Descr=.+Конфликт!){
                    
                    $solidTime = $1 . $2 . $3;
                    $connectID = $4;
                    $eventsearched = 1;

                    #print "ID $connectID \n";

                    given($row)
                    {
                        
                        when($_ ~~ /Context=([^'].+?)[,\n]/ && $multiline == 0){

                            
                            $key = $1;
                            chomp($key);
                            
                            $excp_data{$connectID}{$solidTime} = $key;

                            $solidTime = 0;
                            $connectID = 0;
                            $multiline = 0;
                            $eventsearched = 0;
                            $key = "";
                        }
                        when($_ ~~ /Context='/ && $multiline == 0){

                            my $ind = index($row,"Context='") + 8;

                            my $lenght = length $row;
                            $key = ($ind == -1 ? '': substr($row, $ind + 1, $lenght - 1));
                            $key =~ s![\s]!!g;

                            $multiline = 1;
                         }
                         
                    }
                    
                }elsif($multiline == 0 && $eventsearched == 1 && $row =~ m/Context='/ ){
                    
                    my $ind = index($row,"Context='") + 8;
                    my $lenght = length $row;
                    $key = ($ind == -1 ? '': substr($row, $ind + 1, $lenght - 1));
                    $key =~ s![\s]!!g;
                    my $def = $key eq "";
                    chomp($key);

                    $multiline = 1;

                }elsif($multiline == 1  && $eventsearched == 1){
                             
                    my $ind_close = index($row,"'");
                    
                    if($ind_close != -1){

                        my $lenght = length $row;

                        my $con_key = substr($row, 1, $ind_close - 1); 
                        $con_key =~ s![\s]!!g; 
                                    
                        $key = $key . $con_key;

                        $excp_data{$connectID}{$solidTime} = $key;

                        $solidTime = 0;
                        $connectID = 0;
                        $multiline = 0;
                        $eventsearched = 0;
                                    
                    }else{$row =~ s![\s]!!g; $key = $key . $row}
                }
            }
        }
         close $file;                   
    }

    store \%excp_data, $res_filename;
    #close $res_file;

    return $res_filename;
}

sub lockSearch{
    my ($head, $root_dir,$glob_exp, $res_dir,$is_tmp) = @_;
    
    my $tmp_dir = $res_dir . '/' . 'tmp';
    mkdir $tmp_dir if $is_tmp && ! -d $tmp_dir;

    my $res_filename_owner = ($is_tmp ? $tmp_dir : $res_dir) . "/TLOCK_owner";
    my $res_filename_victim = ($is_tmp ? $tmp_dir : $res_dir) . "/TLOCK_WID_victim";
    my $res_filename_conID_victim = ($is_tmp ? $tmp_dir : $res_dir) . "/TLOCK_CID_victim";
    $tmp_dir = undef;

    my $eventsearched = 0;
    my $multiline = 0;
    my $connectID = 0;
    my $waitconnectID = 0;
    my $solidTime = 0;
    my $dur = 0;
    my $region = "";
    my $key = "";
    my @regions;
    
    my %lock_data_owner;
    my %lock_data_victim;
    my %lock_data_victim_connID;
    

    chdir $root_dir or die "Ошибка обнаружения корневой директории искомых файлов: $!";
    my @glob_arg = glob ($glob_exp) or die "Ошибка поиска файлов по заданному шаблону: $!";

    #open(my $res_file_active, '>:encoding(UTF-8)', $res_filename_active)
    #            or die "Could not open result file '$res_filename_active' $!";
    #open(my $res_file_passive, '>:encoding(UTF-8)', $res_filename_passive)
    #            or die "Could not open result file '$res_filename_passive' $!";

    if(@glob_arg > 0){
        foreach $filename (@glob_arg) {
            open(my $file, '<:encoding(UTF-8)', $filename)
                or die "Could not open file '$filename' $!";
            
            while (my $row = <$file>) {
                if($row =~ m!^(\d{2}):(\d{2})\.(\d{6})-(\d+),TLOCK,.+,t:connectID=(\d+),.+,Regions=(.+),Locks=.+,.+,WaitConnections=(\d*),!){
                    $solidTime = $1 . $2 . $3;
                    $dur = $4;
                    $connectID = $5;
                    $region = $6;
                    $region =~ s!'!!g;
                    @regions = split(",",$region);

                    #print "$region\n@regions\n";

                    $waitconnectID = ($7 eq ""? 0: $7);
                    $eventsearched = 1;

                    #print "ID $connectID \n";

                    given($row)
                    {
                        
                        when($_ ~~ /Context=([^'].+?)[,\n]/ && $multiline == 0){

                            
                            $key = $1;
                            chomp($key);
                            
                            if($waitconnectID == 0){
                                foreach my $reg (@regions){
                                    $lock_data_owner{$connectID}{$solidTime}{$reg} = ($dur . "," . $key);
                                    #print "1 inside loop $lock_data_owner{$connectID}{$solidTime}{$reg}" . "\n";
                                }
                                
                                #print $res_file_active "$solidTime,$dur,TLOCK,t:connectID=$connectID,WaitConnections=$waitconnectID,Region=$region,Context=$key\n";
                            }else{
                                foreach my $reg (@regions){
                                    #print "1 1 $key \n";
                                    #print "1 1 inside loop";
                                    $lock_data_victim{$waitconnectID}{$solidTime}{$reg} = ($dur . "," . $connectID . "," . $key);
                                    $lock_data_victim_connID{$connectID}{$solidTime}{$reg} = ($dur . "," . $waitconnectID . "," . $key);
                                }
                                #print $res_file_passive "$solidTime,$dur,TLOCK,t:connectID=$connectID,WaitConnections=$waitconnectID,Region=$region,Context=$key\n";
                            };
                            

                            #print $duration{$key};
                            $solidTime = 0;
                            $connectID = 0;
                            $multiline = 0;
                            $eventsearched = 0;
                            $key = "";
                        }
                        when($_ ~~ /Context='/ && $multiline == 0){

                            
                            #print "$filename multiline $row \n------------------\n";

                            #print "$_ \n------------------\n";
                            my $ind = index($row,"Context='") + 8;
                            #print $ind;
                            my $lenght = length $row;
                            $key = ($ind == -1 ? '': substr($row, $ind + 1, $lenght - 1));
                            #print "2 $key \n";
                            #print "$key \n------------------\n";
                            #print "$key \n";
                            $key =~ s![\s]!!g;

                            $multiline = 1;
                         }
                         
                    }
                    
                }elsif($multiline == 0 && $eventsearched == 1 && $row =~ m/Context='/ ){
                        #print "$filename multiline $row \n------------------\n";

                            #print "$_ \n------------------\n";
                            my $ind = index($row,"Context='") + 8;
                            #print $ind;
                            my $lenght = length $row;
                            $key = ($ind == -1 ? '': substr($row, $ind + 1, $lenght - 1));
                            $key =~ s![\s]!!g;
            
                            #print "1 $key \n------------------\n";
                            #print " $def \n------------------\n";
                            #print "$key \n";
                            chomp($key);

                            $multiline = 1;
                }elsif($multiline == 1  && $eventsearched == 1){
                             
        my $ind_close = index($row,"'");
            if($ind_close != -1){

        my $lenght = length $row;

                                    #print substr($row, 1,$ind_close - 1);
                                    #print "$key \n------------------\n";
                                    #print "ROW $row \n------------------\n";

        my $con_key = substr($row, 1, $ind_close - 1); 
        $con_key =~ s![\s]!!g; 
                                    #chomp($con_key);
                                    #print "CON $con_key \n------------------\n";
        $key = $key . $con_key;
        
                            
                            if($waitconnectID == 0){
                                        
                               foreach my $reg (@regions){
                                    
                                    $lock_data_owner{$connectID}{$solidTime}{$reg} = ($dur . "," . $key);
                                    #print "3 inside loop $lock_data_owner{$connectID}{$solidTime}{$reg}\n";
                                }
                                #print $res_file_active "$solidTime,$dur,TLOCK,t:connectID=$connectID,WaitConnections=$waitconnectID,Region=$region,Context=$key\n";
                                #print  $region . "\n" if $region =~ m!Locks=!;
                            }else{
                                #print "3 \n@regions\n";
                                foreach my $reg (@regions){
                                    #print "3 \n$waitconnectID\n";

                                    #print "\n$key\n" if $connectID == "168703" && $reg == "BPr718.REFLOCK";
                                    $lock_data_victim{$waitconnectID}{$solidTime}{$reg} = ($dur . "," . $connectID . "," . $key);
                                    $lock_data_victim_connID{$connectID}{$solidTime}{$reg} = ($dur . "," . $waitconnectID . "," . $key);
                                }
                            };
                                    #print "KEY $key \n------------------\n";
        $solidTime = 0;
        $connectID = 0;
        $multiline = 0;
        $eventsearched = 0;
                                    
        }else{$row =~ s![\s]!!g; $key = $key . $row}
        }
        }
    }
         close $file;                   
    }
    #close $res_file_active;
    #close $res_file_passive;

    store \%lock_data_owner, $res_filename_owner;
    store \%lock_data_victim, $res_filename_victim;
    store \%lock_data_victim_connID, $res_filename_conID_victim;

    return $res_filename_owner . "," . $res_filename_victim . "," . $res_filename_conID_victim;
}


return 1;