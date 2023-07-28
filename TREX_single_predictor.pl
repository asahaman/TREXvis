#!usr/bin/perl
use List::Util qw( shuffle ); $path = `pwd`; chomp $path;
open (OUT2, ">evaluation_matrix_deltaacc"); print OUT2 
"Overall\t\tOriginal\t";
open (IN, $ARGV[0]); @file = split (/[_\.]/,$ARGV[0]); $orig_train_file = '';
for $n (0..$#file-2){ $orig_train_file .= "$file[$n]_";} $orig_train_file .= 
$file[$#file-1];

#create two directories "trained_model" and "temp_datasets". The files will 
be stored there
#The command below trains the original model
`java weka.classifiers.trees.RandomForest -I 100 -K 0 -S 1 -num-slots 32 -t 
$path/$ARGV[0] -d $path/trained_models/${orig_train_file}.model`;

#Training file is opened and predictor names are identified and stored in 
array
@pred = ();
while (<IN>){ chomp $_; if ($_=~m/^\@ATT.*?\s(.*?)\s.*/){ if ($1 ne "class"){ 
push (@pred, $1); print OUT2 "$1\t";}}}
close IN; print OUT2"\n";
open (IN1, $ARGV[1]); @file = split (/[_\.]/,$ARGV[1]); $orig_test_file = '';
for $z (0..$#file-2){ $orig_test_file .= "$file[$z]_";} $orig_test_file .= 
$file[$#file-1];

#Original test data evaluated against original model
`java weka.classifiers.trees.RandomForest -l 
"$path/trained_models/${orig_train_file}.model" -T 
$path/${orig_test_file}.arff > $path/temp_datas
ets/orig_teststat`;
open (IN3, "$path/temp_datasets/orig_teststat");
while (<IN3>){ chomp $_; if ($_=~m/^Correctly.*?\d+\s+(\d.*?)\s+%$/){ 
$orig_orig = sprintf ("%.2f",$1); print OUT2 "$orig_orig\tOriginal\tNA\t"
;}} close IN3; 

#variable orig_orig stores accuracy of the original test file
for $x (0..$#pred){ #randomizing each predictor in original test file
open (OUT, 
">$path/temp_datasets/${orig_test_file}_random$pred[$x].arff");
$line = 0; @chosen_pred = (); open (IN1, $ARGV[1]); 

#the original test file is read and the predictor in current loop $x is randomized
while (<IN1>){ chomp $_; if ($_=~m/.*?,[12]$/){ $line++; @{'val'.$line} = 
split (/,/,$_); for $z (0..$#{'val'.$line}){
if ($z == $x){ push (@chosen_pred, ${'val'.$line}[$z]);}}}}
@random_pred = shuffle 0..$#chosen_pred; close IN1;

#The original test file is opened again and is identically re-written 
except the randomized $x predictor 
open (IN1, $ARGV[1]); $instance = 0; while (<IN1>){ chomp $_; if 
($_=~m/.*?,[12]$/){ $instance++;
for $n (0..$#{'val'.$instance}-1){ if ($n == $x){ print OUT 
"$chosen_pred[$random_pred[$instance-1]],";} else { print OUT "${'v
al'.$instance}[$n],"; }}
print OUT "${'val'.$instance}[$#{'val'.$instance}]\n";} else {print 
OUT $_,"\n";}}

#evaluating each randomized test file against original model
`java weka.classifiers.trees.RandomForest -l 
"$path/trained_models/${orig_train_file}.model" -T 
$path/temp_datasets/${orig_test_file}_r
andom$pred[$x].arff > $path/temp_datasets/orig_random$pred[$x]`;

#delta accuracy of each randomized predictor test file compared against 
original test file. Printed to evaluation_matrix_entire file
open (IN3, "$path/temp_datasets/orig_random$pred[$x]"); while (<IN3>){ 
chomp $_; if ($_=~m/^Correctly.*?\d+\s+(\d.*?)\s+%$/){ $delta_ac
c = sprintf ("%.2f", $orig_orig - $1); print OUT2 $delta_acc,"\t";}} close 
IN3;
}
print OUT2 "\n"; 
for $n (0..$#pred){ #stripping each predictor one by one in train file
open (OUT, 
">$path/temp_datasets/${orig_train_file}_minus$pred[$n].arff"); open (IN, 
$ARGV[0]);
while (<IN>){ chomp $_; if ($_=~m/^\@ATT.*?\s(.*?)\s.*/){ print OUT 
"$_\n" unless $1 eq $pred[$n]; } elsif ($_=~m/,[12]$/){
@values = split(/,/,$_); for $y (0..$#values-1){ print OUT 
"$values[$y]," unless $y == $n;} print OUT $values[$#values],"\n";}
else { print OUT $_,"\n";}} close IN;

#The command below trains different models for each predictor instance $n 
excluded
`java weka.classifiers.trees.RandomForest -I 100 -K 0 -S 1 -num-slots 32 
-t $path/temp_datasets/${orig_train_file}_minus$pred[$n].arff 
-d $path/trained_models/${orig_train_file}_minus$pred[$n].model`;
open (IN1, $ARGV[1]); open (OUT, 
">$path/temp_datasets/${orig_test_file}_minus$pred[$n].arff");
while (<IN1>){ #stripping each predictor one by one in test file
chomp $_; if ($_=~m/^\@ATT.*?\s(.*?)\s.*/){ print OUT "$_\n" unless 
$1 eq $pred[$n]; }
elsif ($_=~m/,[12]$/){ @values = split(/,/,$_); for $y (0..$#values1){ print OUT "$values[$y]," unless $y == $n;} print OUT $v
alues[$#values],"\n";}
else { print OUT $_,"\n";}} close IN1;

#evluating model with stripped predictors against test dataset with that 
stripped predictor (no randomization)
`java weka.classifiers.trees.RandomForest -l 
"$path/trained_models/${orig_train_file}_minus$pred[$n].model" -T 
$path/temp_datasets/${or
ig_test_file}_minus$pred[$n].arff > $path/temp_datasets/minus$pred[$n]`;
open (IN3, "$path/temp_datasets/minus$pred[$n]"); while (<IN3>){ chomp 
$_; if ($_=~m/^Correctly.*?\d+\s+(\d.*?)\s+%$/){ $acc_minus = sp
rintf("%.2f",$1); $delta_orig = sprintf("%.2f", $orig_orig - $1); print OUT2 
$acc_minus,"\t$pred[$n]\t",$delta_orig,"\t";}} close IN3;
#Now we need to store all predictors of stripped test file and randomize 
them one by one. This process is repeated for all stripped ins
tances by the master loop $n
open (IN2, "$path/temp_datasets/${orig_test_file}_minus$pred[$n].arff"); 
@test_strip_pred = (); while (<IN2>){ chomp $_; if ($_=~m/^\@A
TT.*?\s(.*?)\s.*/){ push (@test_strip_pred, $1) unless $1 eq "class"; }} 
close IN2; 
$pred_printed = 0;
for $a (0..$#test_strip_pred){ open (IN2, 
"$path/temp_datasets/${orig_test_file}_minus$pred[$n].arff"); $line1 = 0; 
@chosen_test_pred =
();
open (OUT1, 
">$path/temp_datasets/${orig_test_file}_minus$pred[$n]_random$test_strip_pred
309
[$a].arff");
while (<IN2>){ chomp $_; if ($_=~m/.*?,[12]$/){ $line1++; 
@{'tval'.$line1} = split (/,/,$_);
for $b (0..$#{'tval'.$line1}){ if ($b == $a){ push 
(@chosen_test_pred, ${'tval'.$line1}[$b]);}}}}
@random_test_pred = shuffle 0..$#chosen_test_pred; close IN2; open 
(IN2, "$path/temp_datasets/${orig_test_file}_minus$pred[$n].
arff"); $test_instance = 0;
#the stripped test file is re-written except the randomized $a 
predictor
while (<IN2>){ chomp $_; if ($_=~m/.*?,[12]$/){ $test_instance++; 
for $c (0..$#{'tval'.$test_instance}-1){
if ($c == $a){ print OUT1 
"$chosen_test_pred[$random_test_pred[$test_instance-1]],";} else { print OUT1 
"${'tval'.$test
_instance}[$c],"; }}
print OUT1 
"${'tval'.$test_instance}[$#{'tval'.$test_instance}]\n";} else {print OUT1 
$_,"\n";}}
#evaluating stripped predictor training model against that stripped 
predictor test file randomized for every other $a predictor
`java weka.classifiers.trees.RandomForest -l 
"$path/trained_models/${orig_train_file}_minus$pred[$n].model" -T 
$path/temp_datas
ets/${orig_test_file}_minus$pred[$n]_random$test_strip_pred[$a].arff > 
$path/temp_datasets/minus$pred[$n]_random$test_strip_pred[$a]`;
if ($pred_printed == $n){ print OUT2 "NA\t"; $pred_printed++; open 
(IN3, "$path/temp_datasets/minus$pred[$n]_random$test_strip_
pred[$a]");
while (<IN3>){ chomp $_; if 
($_=~m/^Correctly.*?\d+\s+(\d.*?)\s+%$/){ $delta_accminus = sprintf("%.2f", 
$acc_minus - $1
); print OUT2 $delta_accminus,"\t"; }} close IN3; }
else { open (IN3, 
"$path/temp_datasets/minus$pred[$n]_random$test_strip_pred[$a]"); while 
(<IN3>){ chomp $_; if ($_=~m/^Correct
ly.*?\d+\s+(\d.*?)\s+%$/)
{ $delta_accminus = sprintf("%.2f", $acc_minus - $1); print 
OUT2 $delta_accminus,"\t"; $pred_printed++; if ($n == $#pre
d && $pred_printed == $#pred){ print OUT2 "NA\t"}}} close IN3;}
}
#new line to separate rows containing excluded predictor of training 
print OUT2 "\n";
}
