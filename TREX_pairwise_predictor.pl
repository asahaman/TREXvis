#!usr/bin/perl
use List::Util qw( shuffle ); $path = `pwd`; chomp $path;
open (IN, $ARGV[0]); @file = split (/[_\.]/,$ARGV[0]); $orig_train_file = '';
for $n (0..$#file-2){ $orig_train_file .= "$file[$n]_";} $orig_train_file .= 
$file[$#file-1];
open (IN1, $ARGV[1]); @file = split (/[_\.]/,$ARGV[1]); $orig_test_file = '';
for $z (0..$#file-2){ $orig_test_file .= "$file[$z]_";} $orig_test_file .= 
$file[$#file-1];
#print "Enter two (only) predictors' numbers you wish to exclude\n";
@pred_train = (); $line = 0;
while (<IN>){ 
chomp $_; 
if ($_=~m/^\@ATT.*?\s(.*?)\s.*/){ push (@pred_train, $1) unless $1 eq 
"class"; }
if ($_=~m/^(.+?),([12])$/){ $line++; @{'annot_train'.$line} = 
split(/,/,$1); push (@{'annot_train'.$line}, $2); }
} close IN;
#for $n (0..$#pred_train){ $pred_train = $n+1; print "$pred_train 
$pred_train[$n]\n";}
#$input = <STDIN>; chomp $input;
@exclude = split(/,/,$ARGV[2]);
#print "you excluded $pred_train[$exclude[0]-1] and $pred_train[$exclude[1]-
1] predictors\n";
open (OUT, 
">$path/temp_datasets/${orig_train_file}_minus$pred_train[$exclude[0]-
1]$pred_train[$exclude[1]-1].arff");
open (OUT2, ">doubleknockout_deltaacc_$pred_train[$exclude[0]-
1]$pred_train[$exclude[1]-1]");
$l = 0; open (IN, $ARGV[0]);
while (<IN>){
chomp $_;
if ($_=~m/^\@ATT.*?\s(.*?)\s.*/){ print OUT "$_\n" unless $1 eq 
$pred_train[$exclude[0]-1] || $1 eq $pred_train[$exclude[1]-1];}
elsif ($_=~m/.+?,[12]$/){ $l++;
for $n (0..$#{'annot_train'.$l}-1){ print OUT 
"${'annot_train'.$l}[$n]," unless $n == $exclude[0]-1 || $n == $exclude[1]-1 
;} 
print OUT ${'annot_train'.$l}[$#{'annot_train'.$l}],"\n";
}
else {print OUT $_,"\n";}
}
#print "training double knockout model\n";
`java weka.classifiers.trees.RandomForest -I 100 -K 0 -S 1 -num-slots 32 -t 
$path/temp_datasets/${orig_train_file}_minus$pred_train[$exclude[0]
-1]$pred_train[$exclude[1]-1].arff -d 
$path/trained_models/${orig_train_file}_minus$pred_train[$exclude[0]-
1]$pred_train[$exclude[1]-1].model`;
open (OUT, 
">$path/temp_datasets/${orig_test_file}_minus$pred_train[$exclude[0]-
1]$pred_train[$exclude[1]-1].arff"); $l1 = 0; 
while (<IN1>){ chomp $_; if ($_=~m/^(.+?),([12])$/){ $l1++; 
@{'annot_test'.$l1} = split(/,/,$1); push (@{'annot_test'.$l1}, $2); }} close 
IN1;
311
open (IN1, "$ARGV[1]"); $l2 = 0; @incl_test_pred = ();
while (<IN1>){ chomp $_; $t = 0;
if ($_=~m/^\@ATT.*?\s(.*?)\s.*/){ 
print OUT "$_\n" unless $1 eq $pred_train[$exclude[0]-1] || $1 eq 
$pred_train[$exclude[1]-1];
push (@incl_test_pred, $1) unless $1 eq "class";
}
elsif ($_=~m/.+?,[12]$/){ $l2++; 
for $n (0..$#{'annot_test'.$l2}-1){ 
print OUT "${'annot_test'.$l2}[$n]," unless $n == $exclude[0]-1 
|| $n == $exclude[1]-1 ;
push (@{'chosen_test_pred'.$t}, ${'annot_test'.$l2}[$n]) ; 
$t++;
}
print OUT ${'annot_test'.$l2}[$#{'annot_test'.$l2}],"\n";
}
else {print OUT $_,"\n";}
}
#evaluating original model against test dataset (no randomization)
#This requires that the original model against original test dataset is 
evaluated in orig_teststat
# consider running 
#`java weka.classifiers.trees.RandomForest -I 100 -K 0 -S 1 -num-slots 32 -t 
$path/$ARGV[0] -d $path/trained_models/${orig_train_file}.model`;
`java weka.classifiers.trees.RandomForest -l 
"$path/trained_models/${orig_train_file}.model" -T 
$path/${orig_test_file}.arff > $path/temp_datas
ets/orig_teststat`; #or if the single predictor exclusion randomization is 
already done, the file orig_teststat should already be within the te
mp_datasets directory
open (IN3, "$path/temp_datasets/orig_teststat"); while (<IN3>){ chomp $_; if 
($_=~m/^Correctly.*?\d+\s+(\d.*?)\s+%$/){ $orig_orig = $1; }} clos
e IN3;
#print "evaluating double knocked model against test dataset (no 
randomization)\n";
`java weka.classifiers.trees.RandomForest -l 
"$path/trained_models/${orig_train_file}_minus$pred_train[$exclude[0]-
1]$pred_train[$exclude[1]-1]
.model" -T 
$path/temp_datasets/${orig_test_file}_minus$pred_train[$exclude[0]-
1]$pred_train[$exclude[1]-1].arff > $path/temp_datasets/minus$pre
d_train[$exclude[0]-1]$pred_train[$exclude[1]-1]`;
open (IN3, "$path/temp_datasets/minus$pred_train[$exclude[0]-
1]$pred_train[$exclude[1]-1]"); while (<IN3>){ chomp $_; if 
($_=~m/^Correctly.*?\d
+\s+(\d.*?)\s+%$/){ $acc_minus = sprintf("%.2f",$1); $delta_orig = 
sprintf("%.2f",$orig_orig - $1); print OUT2 "$acc_minus\t$pred_train[$exclud
e[0]-1]",",","$pred_train[$exclude[1]-1]\t",$delta_orig,"\t";}} close IN3;
for $y (0..$t-1){
if ($y == $exclude[0]-1 || $y == $exclude[1]-1){ print OUT2 "NA\t";}
else { 
@random_test_pred = shuffle 0..$#{'chosen_test_pred'.$y};
$l3 = 0; open (IN1, $ARGV[1]);
open (OUT, 
">$path/temp_datasets/${orig_test_file}_minus$pred_train[$exclude[0]-
312
1]$pred_train[$exclude[1]-1]_random$incl_test_p
red[$y].arff");
while (<IN1>){ chomp $_;
if ($_=~m/^\@ATT.*?\s(.*?)\s.*/){ print OUT "$_\n" unless $1 eq 
$pred_train[$exclude[0]-1] || $1 eq $pred_train[$exclud
e[1]-1];}
elsif ($_=~m/^(.+?),([12])$/){ $l3++; $label = $2; 
@{'annot'.$l3} = split (/,/,$1);
for $x (0..$#{'annot'.$l3}){ 
print OUT "${'annot'.$l3}[$x]," unless $x == 
$exclude[0]-1 || $x == $exclude[1]-1 || $x == $y;
if ($x == $y){ print OUT 
"${'chosen_test_pred'.$y}[$random_test_pred[$l3]],";} 
}
print OUT $label,"\n";
}
else {print OUT $_,"\n";}
} close IN1;
#print "evaluating double knocked model against test dataset 
randomized predictor $incl_test_pred[$y] . Count $y+1 out of total
$t possibilities\n";
`java weka.classifiers.trees.RandomForest -l 
"$path/trained_models/${orig_train_file}_minus$pred_train[$exclude[0]-
1]$pred_trai
n[$exclude[1]-1].model" -T 
$path/temp_datasets/${orig_test_file}_minus$pred_train[$exclude[0]-
1]$pred_train[$exclude[1]-1]_random$incl_test_pre
d[$y].arff > $path/temp_datasets/minus$pred_train[$exclude[0]-
1]$pred_train[$exclude[1]-1]_random$incl_test_pred[$y]`;
open (IN3, "$path/temp_datasets/minus$pred_train[$exclude[0]-
1]$pred_train[$exclude[1]-1]_random$incl_test_pred[$y]");
while (<IN3>){ chomp $_; if 
($_=~m/^Correctly.*?\d+\s+(\d.*?)\s+%$/){ $delta_accminus = sprintf("%.2f", 
$acc_minus - $1); print
OUT2 $delta_accminus,"\t"; }} close IN3;
}
}
print OUT2 "\n";

