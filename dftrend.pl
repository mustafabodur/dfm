#!/usr/bin/perl
#Disk kullanim oranlarini takip eden ve uyari maili atan  script.
#
# A script to watch disk usage trends and send warning mail
#
# Mustafa Bodur 2009-Aug
#
#
# Watch diskfree compares with the previous one. Calculates how long will it take to fill with the current trend
# Calculated on 5 minute avarage
#
# Bos kalan alan miktarini izler ve artis oranina gore ne kadar sure sonra dolacagini hesaplar.
# 5 dakikalik ortalamalar alarak calisir.
#
#
#Version 0.28
#



use Socket;
use Sys::Hostname;

use vars qw( @cap @dfh @fs @size @used @avail @fil @mount @trfs @capmount @emailnot);

$version="0.28";
$lang="";
$year=`date  +%Y`;
$month=`date +%m`;
$day=`date +%d`;

chomp($year);
chomp($month);
chomp($day);
$path="/admins/dfm/stats/$year/$month/$day/";
#print "$path path:";
$rpath="/admins/dfm/stats/";
unless(-d "$rpath/$year"){
    mkdir ("$rpath/$year") or die;
}
unless(-d "$rpath/$year/$month"){
    mkdir ("$rpath/$year/$month" ) or die;
}
unless(-d "$rpath/$year/$month/$day"){
    mkdir ( "$rpath/$year/$month/$day") or die;
}
$prev=$rpath."dfstat.prev";


@emails=`cat /admins/dfm/dfusers`;
@cap=`cat /admins/dfm/dfopts`;
@trop=`cat /admins/dfm/dftrend.opts | grep -v "^#"`;


$unixtype=`uname`;
chomp($unixtype);
if ($unixtype eq "SunOS") {
        @df=`df -k |grep -v "Filesystem            kbytes    used   avail capacity  Mounted on"`;
        @dfh=`df -h | grep -v "Filesystem            kbytes    used   avail capacity  Mounted on"`;
                @pdf=`cat $prev | grep -v "Filesystem            kbytes    used   avail capacity  Mounted on"`;

}
if ($unixtype eq "Linux") {
        #@df=`df -kP |grep -v "^Filesystem"| grep -v "^tmpfs"`;
        #@dfh=`df -h | grep -v "Filesystem            kbytes    used   avail capacity  Mounted on"`;
        @df=`df -lkP -x tmpfs |grep -v "^Filesystem"`;
        @dfh=`df -hlkP -x tmpfs |grep -v "^Filesystem"`;
        @pdf=`cat $prev |grep -v "^Filesystem"| grep -v "^tmpfs"`;

}



$time=`date +%Y%m%d`;
$datetime =`date +%Y%m%d-%H%M`;
$tperiod=5; #Bes dakika aralikli calisiyor ise / 5 minutes period
$i=0;
$j=0;
$k=0;
$m=0;


$hostname = hostname();
#$addr = inet_ntoa(scalar(gethostbyname($hostname)) || 'localhost');
$addr = inet_ntoa(pack("N", scalar(gethostbyname($hostname)) || 'localhost'));

for ($i=0;$i<=$#ARGV;$i++) {
        if (($ARGV[$i] eq "-e") or ($ARGV[$i] eq "-email") or  ($ARGV[$i] eq "email")){
                $email=1;
        }
        if (($ARGV[$i] eq "-v") or ($ARGV[$i] eq "-version") or  ($ARGV[$i] eq "version")){
                print $version."\n";
                exit;
        }
        if (($ARGV[$i] eq "test") or ($ARGV[$i] eq "-test") or ($ARGV[$i] eq "-t") ) {
                $test=1;
        }
        if (($ARGV[$i] eq "simple") or ($ARGV[$i] eq "-simple") or ($ARGV[$i] eq "-s") ) {
                $simple=1;
        }
        if (($ARGV[$i] eq "debug") or ($ARGV[$i] eq "-debug") or ($ARGV[$i] eq "-d") ) {
                $debug=$ARGV[$i+1];
        }
        if (($ARGV[$i] eq "extended") or ($ARGV[$i] eq "-extended") or ($ARGV[$i] eq "-ex") ) {
                $extended=1;
        }
        if (($ARGV[$i] eq "lowmark") or ($ARGV[$i] eq "-lowmark") or ($ARGV[$i] eq "-lm") ) {
                $enablelowmark=1;
        }
        if (($ARGV[$i] eq "noupdate") or ($ARGV[$i] eq "-noupdate") or ($ARGV[$i] eq "-nu") ) {
                $noupdate=1;
        }
        if (($ARGV[$i] eq "showbyte") or ($ARGV[$i] eq "-showbyte") or ($ARGV[$i] eq "-sb") ) {
                $showbyte=1;
        }
        if (($ARGV[$i] eq "usedb") or ($ARGV[$i] eq "-usedb") or ($ARGV[$i] eq "-db") ) {
        use DBI;
        $usedb=1;
        $dbname="dfm";
        $dbhost="172.18.9.100";
        $port="5432";
        $username="dfm";
        $dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$dbhost;port=$port",
                      $username,
                      $password,
                      {AutoCommit => 1, RaiseError => 1, PrintError => 1}
                     );
        use DBD::Pg qw(:pg_types);

        $dbh->do('INSERT INTO df( host,used,free,avail,size) VALUES ( $host,$used,$free,$avail,$size)');

        $sth = $dbh->prepare('INSERT INTO df( host,fs,used,free,avail,size) VALUES (?,?,?,?,?,?)');
        $sth->execute( $host,$fs,$used,$free,$avail,$size) or print  $dbh->errstr;
        }
}
$i=0;
foreach $trops (@trop) {
                ($trfs[$m],$trlowmark[$m],$trtrend[$m],$trused[$m],$trttf[$m],$trmix[$m],$trwarngroup[$m])=split(/\s+/,$trops);
                if (length($trfs[$m])>0) {
                        $m++;
                }
        }
foreach $dfs (@df) {
        ($fs[$i],$size[$i],$used[$i],$avail[$i],$fil[$i],$mount[$i])=split(/\s+/,$dfs);
        if ($debug > 4) {
                print "i $i fs: $fs[$i] size: $size[$i] used: $used[$i] avail: $avail[$i] fil: $fil[$i] mount: $mount[$i]\n";
        }
        chop($fil[$i]); # remove trail %
        $i++;
}

foreach $pdfs (@pdf) {
        ($pfs[$j],$psize[$j],$pused[$j],$pavail[$j],$pfil[$j],$pmount[$j])=split(/\s+/,$pdfs);
        $j++;
#       print "pdfs $pdfs\n";
}
foreach $dfhs (@dfh) {
        #       print "dfs $dfs\n";
        ($hfs[$k],$hsize[$k],$hused[$k],$havail[$k],$hfil[$k],$hmount[$k])=split(/\s+/,$dfhs);
        chop($hfil[$k]); # remove trail %
        $k++;

}
$m=0;
$k=0;
$j=0;
foreach $ca (@cap) {
        ($capfil[$j],$capmount[$j],$emailnot[$j])=split(/\s+/,$ca);
        $j++;
}
sub add_content($) {
        $chkcontent=shift;
        if($chkcontent ne "") {
                $content.=$chkcontent;
        }
}
sub add_precontent($) {
        $chkcontent=shift;
        if($chkcontent ne "") {
                $content=$chkcontent.$content;
        }
}
sub bth($) {
        $kbyte=shift;
        $kilo=1024;
        $mega=1024;
        #$giga=1024*$mega;
        $giga=1000*$mega;
        $tera=1024*$giga;
        if (($kbyte/$mega)>1) {
                $ret= sprintf "%.2f",($kbyte/$mega);
                $ret.="M";
        }
        if (($kbyte/$giga)>1) {
                $ret= sprintf "%.2f",($kbyte/$giga);
                $ret.="G";
        }
        if (($kbyte/$tera)>1) {
                $ret= sprintf "%.2f",($kbyte/$tera);
                $ret.="T";
        }
        return $ret;
}
sub lookupuser_mail($) {
        my $lookupuser=shift;
        my $usermail ="";
        foreach $userl (@emails) {
                 chomp($userl);
                ($mailgroup,$aemail)=split(/\s+/,$userl);
                if($lookupuser eq $mailgroup) {
                        $usermail=$aemail;
                        }
                }
        $emailuser =~ s/\@/\\\@/g;
        if ($debug>4) {
               print "user $lookupuser email $usermail \n";
        }
        return $usermail;

}

sub sendmail ($$$) {
        my $content = shift;
        $send_to = "To: ".shift()."\n";
        my $subject = shift;
        my $sendmail = "/usr/sbin/sendmail -t";
        my $reply_to = "Reply-to: root\@".$hostname."\n";
        if ($subject eq "" ) {

                if ($lang=="tur") { 
                          $subject = " Disk Kullanim  Trendi";
                } else {
                          $subject = " Disk Usage   Trends";
                }
        $subject ="Subject: ".$subject;
        if ($test eq 1 ) {
                $send_to = "To: testuser\@yourdefault.domain.com\n";
        }
        if ($test eq 1 ) {
                $subject .= "(Testing)";
        }
        if ($lang=="tur") {
                my $from="From: \<Disk Alan Kontrolu\> DfCheck\@$hostname\n";
                } else {
                my $from="From: \<Disk Free Monitor \> DfCheck\@$hostname\n";
                }
        if($noemail ne 1) {
                open(SENDMAIL, "|$sendmail") or die "Cannot open $sendmail: $!";
                #open(SENDMAIL,">./sendfile");
                print SENDMAIL $from;
                print SENDMAIL $send_to;
                print SENDMAIL $reply_to;
                print SENDMAIL $subject."\n";
                print SENDMAIL "Content-type: text/plain\n\n";
                print SENDMAIL $content;
        }

}








sub print_array(@) {
        my @ar=@_;
        print "dumping array\n";
        foreach $arr (@ar) {
                print "arr=$arr\n";
        }
}

sub check_fill_extended() {
        if ($debug>3) {
                print "array size fs $#fs\n";
        }
        $i=0;
        for($i=0;$i<=$#trfs;$i++) {
        $idx=undef;
        $pidx=undef;
        $cidx=undef;
        if ($noupdate ne 1) {
                if ($debug>1) {
                        print "path:".$path."dfstat.".$datetime."\n";
                }
                write_file("$path$datetime",@df);
                write_file("$rpath/dfstat.prev",@df);



                        print " seeking filesystem $trfs[$i] lowmark: $trlowmark[$i] trend value: $trtrend[$i] minfree: $trused[$i] timetofill: $trttf[$i] mix value: $trmix[$i] warning group: $trwarngroup[$i] \n";
        }
        if ($usedb eq 1 ) {

                $sth = $dbh->prepare('INSERT INTO df( host,fs,used,fillpercent,avail,size,device) VALUES (?,?,?,?,?,?,?)');
                $free[$i]=$size[$i]-$used[$i];
                $sth->execute( $hostname,$mount[$i],$used[$i],$fil[$i],$avail[$i],$size[$i],$fs[$i]) or print  $dbh->errstr;
                 if ($debug>0) {
                 print "db : $hostname $mount[$i],$used[$i],$fil[$i],$avail[$i],$size[$i],$fs[$i]\n";
                }
        }

                $idx=find_fs($trfs[$i],@mount);
                #chop($fil[$idx]); # remove trail %
                if ($debug>3) {
                        print "i $i fs $trfs[$i]\n";
                }


                if ($debug>4) {
                        print "$trfs[$i] idx= $idx mount: $mount[$idx]\n";
                }
                if ($debug>3) {
                        print_array(@mount);
                }
                $pidx=find_fs($trfs[$i],@pmount);
                if ($debug>4) {
                        print "$trfs[$i] pidx= $pidx pmount: $pmount[$pidx]\n";
                }
                if ($debug>3) {
                        print_array(@pmount);
                }
                #$cidx=find_fs($trfs[$i],@capmount);
                #if ($debug>4) {
                #       print "$trfs[$i] pidx= $cidx pmount: $capmount[$cidx]\n";
                #}
                if ($debug>3) {
                        print_array(@capmount);
                }
                $emailuser[$i]=lookupuser_mail($trwarngroup[$i]);
                if ($debug>5) {
                        print "emailing user $emailuser[$i] for group  $trwarngroup[$i] \n";
                        }
                if ($debug>0) {
                        if(  ($fil[$idx] < $trlowmark[$i]) ) {
                                print "\tfill for $trfs[$i] < low mark set for this group  ($fil[$idx] < $trlowmark[$i]) \n";
                        }
                }
                if( ($enablelowmark != 1) or ($fil[$idx] >= $trlowmark[$i]) ) {
                        if ($debug>0) {

                                if  ($enablelowmark != 1){

                                        print "Low mark system disabled.\n";
                                        } else {
                                        print "\tfill for $trfs[$i] > low mark set for this group  ($fil[$idx] > $trlowmark[$i]) \n";
                                }
                        }
                        if ($debug>5) {
                                print "\t idx $idx \n";
                                }
                        if ($debug>2) {
                                print "\tused $used[$idx] and pused $pused[$idx] for fs $trfs[$i]\n";
                                }
                        $trend[$i]=(($used[$idx]-$pused[$pidx])/$pused[$pidx])*100;
                        $delta[$i]=$used[$idx]-$pused[$pidx];
                        if ($debug>2) {
                                print "\t\ttrend $trend[$i] and delta $delta[$i] for fs $trfs[$i]\n";
                                }
                        #if($trend[$i]>0 and $delta[$i] != 0) {
                        if($delta[$i] != 0) {
                                $delta[$i]=$used[$idx]-$pused[$pidx];
                                $eta[$i]=int($tperiod*($avail[$idx]/$delta[$i]));
                                if ($debug>1) {
                                        print "\ttrend $trend[$i] tretrend $trtrend[$i] avail $avail[$idx] trused $trused[$i] eta $eta[$i]  trtff $trttf[$i]\n";
                                }
                                #$mix[$i]=.2 * ($trend[$i]*100/$trtrend[$i]) + 0.3 *($avail[$idx]*100 / $trused[$i]) + .50 *($eta[$i]*100/$trttf[$i]);
                                $mix[$i]=int(
                                        ( .1 * $trend[$i]*100)+
                                        (.3*(100-(int($used[$idx]*100/$size[$idx])) ))+
                                        (.6 *  (10000/($eta[$i]+1))));
                                if ($debug>1) {
                                        print "\t\teta $eta[$i] and mix $mix[$i] for fs $trfs[$i]\n";
                                }

                                if ($debug>1) {
                                        print "\ttrend= $trend[$i] treshold $trtrend[$i] for fs $trfs[$i]\n";
                                }
                                if($trend[$i] >= $trtrend[$i] ) {
                                        if ($debug>1) {
                                                print "\ttrend ($trend[$i]) is more than treshold ($trtrend[$i]) sending warning mail \n";
                                        }
                                        if ($showbyte == 1) {
                                                if ($lang=="tur") {
                                                        $out= "\n$trfs[$i]\t\t Oncesi: $pused[$pidx] Simdi: $used[$idx] Bos: $avail[$idx]\n";
                                                        } else {
                                                        $out= "\n$trfs[$i]\t\t Previous: $pused[$pidx] Now: $used[$idx] Avail: $avail[$idx]\n";
                                                        }
                                                } else {
                                                if ($lang=="tur") {
                                                        $out= "\n$trfs[$i]\t\t Oncesi: ".bth($pused[$pidx])." Simdi: ".bth($used[$idx])." Bos: ".bth($avail[$idx])."\n";
                                                        } else {
                                                        $out= "\n$trfs[$i]\t\t Previous: ".bth($pused[$pidx])." Now: ".bth($used[$idx])." Avail: ".bth($avail[$idx])."\n";
                                                        }

                                        }
                                        if ($lang=="tur") {
                                                $out.= "\t\t\tArtis yuzdesi % ".int($trend[$i])." uyari siniri (% $trtrend[$i])\n";
                                                $out.= "\t\tDiskin dolmasi icin tahmini sure $eta[$i] dakika\n";
                                                } else {
                                                $out.= "\t\t\tInrease percent  ".int($trend[$i])."% warning threshold ( $trtrend[$i] %)\n";
                                                $out.= "\t\t Estimated time  to full  disk $eta[$i] minutes\n";
                                                }

                                        if ($debug>2) {
                                                print $out."\n";
                                                }
                                        if ($email eq 1) {
                                                add_content($out);
                                                $out="";
                                                } else {
                                                print $out;
                                                }
                                } else {
                                        if ($debug>1) {
                                                print "\ttrend ($trend[$i])  is less than treshold ($trtrend[$i]) . it's in the safe margin \n";
                                        }
                                }
                                }
                                if ($debug>1) {
                                        print "\t\t used $used[$idx] size $size[$idx] for fs $trfs[$i]  \n";
                                        }
                                #if (int($used[$idx]*100/$size[$idx]) >= $trused[$i]) {
                                if ($fil[$idx] >= $trused[$i]) {
                                        if ($debug>1) {
                                                print "\tUsed (".(int($used[$idx]*100/$size[$idx])).") is more than treshold ($trused[$i]) sending warning mail \n";
                                        }

                                        if ($showbyte == 1) {
                                                if ($lang=="tur") {
                                                        $out= "\n$trfs[$i]\t\t Oncesi: $pused[$pidx] Simdi: $used[$idx] Bos: $avail[$idx]\n";
                                                        } else {
                                                        $out= "\n$trfs[$i]\t\t Previous: $pused[$pidx] Now: $used[$idx] Avail: $avail[$idx]\n";
                                                        }
                                                } else {
                                                if ($lang=="tur") {
                                                        $out= "\n$trfs[$i]\t\t Oncesi: ".bth($pused[$pidx])." Simdi: ".bth($used[$idx])." Bos: ".bth($avail[$idx])."\n";
                                                        } else {
                                                        $out= "\n$trfs[$i]\t\t Previous: ".bth($pused[$pidx])." Now: ".bth($used[$idx])." Avail: ".bth($avail[$idx])."\n";
                                                        }
                                        }
                                        #$out.= "\t\t\tDoluluk yuzdesi % ".int($used[$idx]*100/$size[$idx])." (uyari siniri % $trlowmark[$i])\n";
                                        if ($lang=="tur") {
                                                $out.= "\t\t\tDoluluk yuzdesi % ".int($fil[$idx])." (uyari icin  sinir deger % $trused[$i])\n";
                                                } else {
                                                $out.= "\t\t\tFill percent  ".int($fil[$idx])."% (threshold for warning  $trused[$i] %)\n";
                                                }
                                        if ($eta[$i] > 0 ) {
                                                if ($lang=="tur") {
                                                $out.= "\t\tDiskin dolmasi icin tahmini sure $eta[$i] dakika\n";
                                                } else {
                                                $out.= "\t\tEstimated time to full disk $eta[$i] minutes\n";
                                                }
                                        }
                                        if ($debug>2) {
                                                print $out."\n";
                                                }
                                        if ($email eq 1) {
                                                add_content($out);
                                                $out="";
                                                } else {
                                                print $out;
                                                }
                                } else {
                                        if ($debug>1) {
                                                #print "\tUsed (".(int($used[$idx]*100/$size[$idx])).")  is less than treshold ($trused[$i]). it's in the safe margin \n";
                                                print "\tUsed (".$fil[$idx].")  is less than treshold ($trused[$i]). it's in the safe margin \n";
                                        }
                                }

                                if (($eta[$i]> 0) and ($eta[$i] <= $trttf[$i] ) ){
                                        if ($debug>1) {
                                                print "\teta ($eta[$i]) is less than treshold($trttf[$i]) sending warning mail \n";
                                        }
                                        if ($showbyte == 1) {
                                                if ($lang=="tur") {
                                                        $out= "\n$trfs[$i]\t\t Oncesi: $pused[$pidx] Simdi: $used[$idx] Bos: $avail[$idx]\n";
                                                        } else {
                                                        $out= "\n$trfs[$i]\t\t Previous: $pused[$pidx] Now: $used[$idx] Avail: $avail[$idx]\n";
                                                        }
                                                } else {
                                                if ($lang=="tur") {
                                                        $out= "\n$trfs[$i]\t\t Oncesi: ".bth($pused[$pidx])." Simdi: ".bth($used[$idx])." Bos: ".bth($avail[$idx])."\n";
                                                        } else {
                                                        $out= "\n$trfs[$i]\t\t Previous: ".bth($pused[$pidx])." Now: ".bth($used[$idx])." Avail: ".bth($avail[$idx])."\n";
                                                        }
                                        }
                                        #$out.= "\t\t\tBos yuzdesi % ".int($avail[$idx]*100/$size[$idx])." \n";
                                        if ($lang=="tur") {
                                                $out.= "\t\t\tDiskin dolmasi icin tahmini sure $eta[$i] dakika (uyari siniri $trttf[$i] dakika) \n";
                                                } else {
                                                $out.= "\t\t\tEstimated time to full disk  $eta[$i] minutes (threshold for warning $trttf[$i] minutes) \n";
                                                }
                                        if ($debug>2) {
                                                print $out."\n";
                                                }
                                        if ($email eq 1) {
                                                add_content($out);
                                                $out="";
                                                } else {
                                                print $out;
                                                }

                                } else {
                                        if ($debug>1) {
                                                print "\teta ($eta[$i])  is more than treshold ($trttf[$i]). it's in the safe margin \n";
                                        }
                                }
                        #       print "mix $mix[$i] trmix $trmix[$i]\n";
                                if($mix[$i] >= $trmix[$i]) {
                                        if ($debug>1) {
                                                print "\tmix ($mix[$i]) value is more than treshold ($trmix[$i]) sending warning mail \n";
                                        }
                                        if ($showbyte == 1) {
                                                if ($lang=="tur") {
                                                        $out= "\n$trfs[$i]\t\t Oncesi: $pused[$pidx] Simdi: $used[$idx] Bos: $avail[$idx]\n";
                                                        } else {
                                                        $out= "\n$trfs[$i]\t\t Previus: $pused[$pidx] Now: $used[$idx] Avail: $avail[$idx]\n";
                                                        }
                                                } else {
                                                if ($lang=="tur") {
                                                        $out= "\n$trfs[$i]\t\t Oncesi: ".bth($pused[$pidx])." Simdi: ".bth($used[$idx])." Bos: ".bth($avail[$idx])."\n";
                                                        } else {
                                                        $out= "\n$trfs[$i]\t\t Previous: ".bth($pused[$pidx])." Now: ".bth($used[$idx])." Avail: ".bth($avail[$idx])."\n";
                                                        }
                                        }
                                        if ($lang=="tur") {
                                                $out.= "\t\tBirlesik uyari degeri $mix[$i] sinir ( $trmix[$i]) \n";
                                                $out.= "\tBos yuzdesi % ".int($avail[$idx]*100/$size[$idx])." ";
                                                $out.= "Diskin dolmasi icin tahmini sure $eta[$i] dakika\n";

                                                $out.="\t\t (Trend agirlik degeri: ".(sprintf "%.2f",( .1 * $trend[$i]*100)).")\n";
                                                $out.="\t\t (Free agirlik degeri: ".(sprintf "%.2f",(.3*( 100-(int($used[$idx]*100/$size[$idx])) ))).")\n";
                                                $out.="\t\t (Eta agirlik degeri: ".(sprintf "%.2f",(.6 *(  (10000/($eta[$i]+1))))).")\n";
                                                } else {
                                                $out.= "\t\tMixed warning value $mix[$i] threshold ( $trmix[$i]) \n";
                                                $out.= "\t Free percent  ".int($avail[$idx]*100/$size[$idx])."% ";
                                                $out.= "Estimated time to full disk $eta[$i] minutes\n";

                                                $out.="\t\t (Trend component value: ".(sprintf "%.2f",( .1 * $trend[$i]*100)).")\n";
                                                $out.="\t\t (Free component value: ".(sprintf "%.2f",(.3*( 100-(int($used[$idx]*100/$size[$idx])) ))).")\n";
                                                $out.="\t\t (Eta component value: ".(sprintf "%.2f",(.6 *(  (10000/($eta[$i]+1))))).")\n";
                                                }
                                        if ($debug>2) {
                                                print $out."\n";
                                                }

                                        if ($email eq 1) {
                                                add_content($out);
                                                $out="";
                                                } else {
                                                print $out;
                                                }
                                } else {
                                        if ($debug>1) {
                                                print "\tmix ($mix[$i]) is less than treshold ($trmix[$i]) . it's in the safe margin \n";
                                        }
                                }


                                if(($email eq 1) and ($content ne "")) {
                                        if ($enablelowmark == 1 ) {
                                                if ($lang=="tur") {
                                                add_precontent("\nDoluluk uyarisi icin  baslama degeri % $trlowmark[$i] \n");
                                                } else {
                                                add_precontent("\nThreshold value for start of warning mails $trlowmark[$i] % \n");
                                                }
                                        }
                                        if ($lang=="tur") {
                                                add_precontent("$trwarngroup[$i] grubu icin disk bos alan kontrol maili \n");
                                                $subject=$hostname." ($addr) sunucusunda $trfs[$i] \% $fil[$idx] dolu";
                                                } else {
                                                add_precontent("Disk Free Monitor mail for group $trwarngroup[$i] \n");
                                                $subject="On server $hostname ($addr) filesystem $trfs[$i]  $fil[$idx] \% full ";
                                                }
                                        sendmail($content,$emailuser[$i],$subject );
                                        $content="";
                                }
                        }
                #}
        #}
        }
}
sub check_fill() {
        $i=0;
        $j=0;
        $hostname = hostname();
        $addr = inet_ntoa(scalar(gethostbyname($hostname)) || 'localhost');
        for ($i=0;$i<=$#capmount;$i++) {
                $hdx=find_fs($capmount[$i],@hmount);
                        if ($hfil[$hdx]>=$capfil[$i]) {

                                $emailuser=lookupuser_mail($emailnot[$j]);
                                if ($lang=="tur") {
                                        $out= $hmount[$hdx]."  %".$hfil[$hdx]." dolu threshold (%".$capfil[$i].")\n";
                                        } else {
                                        $out= $hmount[$hdx]."  ".$hfil[$hdx]." % full  threshold (".$capfil[$i]."%)\n";
                                        }
                                if ($email eq 1) {
                                        add_content($out);
                                        $out="";
                                } else {
                                        print $out;
                                        }
                                if ($lang=="tur") {
                                        $subject=$hostname."($addr) sunucusunda $hmount[$hdx] \% $hfil[$hdx] dolu";
                                        } else {
                                        $subject="On server ".$hostname."($addr) filesystem $hmount[$hdx]  $hfil[$hdx] \% full";
                                        }
                                if(($email eq 1) and ($content ne "")) {
                                        sendmail($content,$emailuser,$subject );
                                         }
                                }
                $content="";
        }

}
sub write_file() {
        my ($file, @data) = @_;

                print "$package, $filename, $line\n";
        }
        if ($debug>1) {
                print "file to update/write $file \n";
        }
        open(FILE,">$file") || die("Cannot Open File $file");
        flock(FILE, LOCK_EX);
        foreach $dfs (@data) {
                print FILE $dfs;
        }
        close(FILE);
}

sub find_fs() {

        if ($debug>3) {
                ($package, $filename, $line) = caller;
                print "$package, $filename, $line\n";
        }
        my ($fs, @arr) = @_;
#       print "number in array $#arr\n";
        $ridx='';
        if ($debug>5) {
                foreach $ar (@arr) {
                        print "$ar \n"

                        }
                print "end\n";
        }
        for($lx=0;$lx<=$#arr;$lx++)  {
        if ($debug>4) {
                print "fs $fs (".length($fs).") array element $arr[$lx] (".length($arr[$lx]).") index $lx \n";

                }
                if($arr[$lx] eq $fs) {
        if ($debug>3) {
                        print "found! $lx \n";
                        print "array element $arr[$lx] index $lx \n";
                }
                        $ridx=$lx;
                        }
                }

        if ($debug>4) {
                if ($ridx ne "") {
                        print "index = $ridx \n";
                }
        }
        return $ridx;

}
if(($email eq 1) and ($content ne "")) {
                if ($test eq 1 ) {
                sendmail($content,"tester\@defaultdomain.com","");
                } else {
                sendmail($content,"monitoruser\@defaultdomain.com","");
                }
        }
if ($extended) {
        check_fill_extended();
exit;
} else {

for($i=0;$i<$#fs;$i++) {
#       print "fs: $fs[$i]\n";
        for($j=0;$j<$#pfs;$j++) {
                if($mount[$i] eq $pmount[$j]) {
                        if($used[$i]>0){
                                $trend=(($used[$i]-$pused[$j])/$pused[$j])*100;
                                if($trend>1) {
                                        $delta=$used[$i]-$pused[$j];

#                                       print "delta $delta \n";
                                        $eta=int($tperiod*($avail[$i]/$delta));
                                        if($eta<10000) {
                                                if ($eta< 1000 or (($avail[$i]*100)/$size[$i])<50) {
                                                        #print "avail ratio:$avail[$i] / $size[$i]) ".($avail[$i]*100)/$size[$i];
                                                        if ($showbyte == 1) {
                                                                if ($lang=="tur") {
                                                                        $out= "\n $fs[$i]\t $mount[$i]\t\t Oncesi: $pused[$j] Simdi: $used[$i] Bos: $avail[$i]\n";
                                                                        } else {
                                                                        $out= "\n $fs[$i]\t $mount[$i]\t\t Previous: $pused[$j] Now: $used[$i] Avail: $avail[$i]\n";
                                                                        }
                                                                } else {
                                                                        if ($lang=="tur") {
                                                                        $out= "\n $fs[$i]\t $mount[$i]\t\t Oncesi: ".bth($pused[$j])." Simdi: ".bth($used[$i])." Bos: ".bth($avail[$i])."\n";
                                                                        } else {
                                                                        $out= "\n $fs[$i]\t $mount[$i]\t\t Previous: ".bth($pused[$j])." Now: ".bth($used[$i])." Avail: ".bth($avail[$i])."\n";
                                                                        }
                                                                }
                                                        if ($lang=="tur") {
                                                                $out.= "\t\t\tArtis yuzdesi % ".int($trend)."\n";
                                                                $out.= "\t\tDiskin dolmasi icin tahmini sure $eta dakika\n";
                                                                } else {
                                                                $out.= "\t\t\tIncrease percent  ".int($trend)." %\n";
                                                                $out.= "\t\ttEstimated time to full disk $eta minutes\n";
                                                                }

                                                        if ($email eq 1) {
                                                                add_content($out);
                                                                $out="";
                                                        } else {
                                                                print $out;
                                                        }
                                                }
                                        }
                                }
                        }


                }
        }
}



}

if ($simple) {
        check_fill();
exit;
}

