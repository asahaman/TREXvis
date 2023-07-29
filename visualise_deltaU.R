#Save the matrix from TREX_single_predictor.pl or TREX_pairwise_predictor.pl into any csv or tsv format file and read it into an R console
file = read.csv("file_deltaacc.csv", sep = ",", na.strings = NA)
row.names(file) = clinvar$X
file = file[,2:ncol(file)]
file_matrix = data.matrix(file)
#Then load the libraries “gplots” and “RcolorBrewer”.
#Package gtools is recommended if the values are non-symmetric about zero as gtools will be required to modify the source code of heatmap.2 function for generating the right colour scale
library(gplots)
library(RcolorBrewer)
#library(gtools) if scale is non symmetric about zero
#Option of choosing different colour intensities from R color brewer
display.brewer.all(5)
#In this case, 5 is the number of colours I want in a set. 
#This gives sets of labels of colors. Choose a set (e.g. YlOrRd)
#brewer.pal(8,”YlOrRd”) # this gives hexadecimal colour codes. Use the colour codes to form my palette. 
my_palette = colorRampPalette(c("#084594","#3288BD","#FED976","#FEB24C","#FD8D3C","#FC4E2A","#E31A1C","#BD0026","#800026","#8C2D04"))(n=999)
#Then design custom colour breaks based on my_palette
col_breaks = c(seq(-15,-3,length=100), seq(-3,0,length=100), seq(0,0.1,length=100), seq(0.1,1,length=100), seq(1,5,length=100), seq(5,10,length=100), seq(10,15,length=100),seq(15,20,length=100), seq(20,30,length=100))
#to go beyond 30 use seq(30,65,length=100)
#Varibench setting 
#col_breaks = c(seq(-20,-2,length=100), seq(-2,0,length=100), 
#seq(0,0.1,length=100), seq(0.1,1,length=100), seq(1,5,length=100), 
#seq(5,10,length=100), seq(10,15,length=100),seq(15,20,length=100), 
#seq(20,30,length=100), seq(30,65,length=100))
#Then use heatmap.2 function
heatmap.2(clinvar_matrix, cellnote = clinvar_matrix, notecol = 
"black",notecex = 1.9, density.info ="none", trace = "none", Colv = "NA", 
Rowv = "NA", margins = c(12.2,15.2), col=my_palette, breaks = col_breaks, 
na.color = "black", srtCol = 45, adjCol = c(0.98,0.8), cexCol = 2,cexRow = 2, 
offsetCol = 0, offsetRow = 0, lmat = rbind(c(4,2),c(3,1)), lwid = c(0.3,10), 
lhei = c(0.1,10), key.xlab = NA, key.par = list(mar=c(2,20,1.5,20), cex=2))
#fonts are controlled by ‘cex’. Margins are controlled by ‘margins’ and 
margins of key are controlled by ‘mar’. The user can play with different 
numbers to get the right size of heatmap and corresponding colour key
#The above function works fine if values are symmetric about zero. #However 
for non-symmetric values about zero, the colour key is #incorrectly generated 
and requires a modification of the source code #of heatmap.2 function. The 
source code of heatmap.2 can be obtained by #typing gplots::heatmap.2 in R 
console. The required modification of #the source code is shown in A2.8. Lets 
say the new user customized #function is denoted by heatmap.3 
#the colour breaks for a key that is not symmetric about zero needs to be non 
overlapping
col_breaks = c(seq(-15,-3.01,length=100), seq(-3,-0.01,length=100), 
seq(0,0.1,length=100), seq(0.11,1,length=100), seq(1.01,5,length=100), 
seq(5.01,10,length=100), seq(10.01,15,length=100),seq(15.01,20,length=100), 
seq(20.01,30,length=100))
heatmap.3(clinvar_matrix, cellnote = clinvar_matrix, notecol = "black", 
density.info ="none", trace = "none", Colv = "NA", Rowv = "NA", margins = 
c(12.2,15.2), col=my_palette, breaks = col_breaks, na.color = "black", srtCol 
= 45, adjCol = c(0.98,0.8), offsetCol = 0, offsetRow = 0, lmat = 
rbind(c(4,2),c(3,1)), lwid = c(0.1,10), lhei = c(3.5,10), symkey=FALSE, 
key.xlab = NA, key.par = list(mar=c(2.2,5,1.5,5), 
cex=2),key.xtickfun=function() { 
 breaks <- parent.frame()$breaks 
 return(list( 
at=parent.frame()$scale01(c(breaks[1],breaks[42],breaks[83],breaks[201],break
s[500],breaks[600],breaks[700],breaks[800],breaks[850],breaks[length(breaks)]
)),
 labels=c(as.character(breaks[1]),-10,-
5,as.character(breaks[201]),as.character(breaks[500]),as.character(breaks[600
]),as.character(breaks[700]),as.character(breaks[800]),25,as.character(breaks
[length(breaks)]))))})
#here the key.xtickfun customizes the colour key and appropriate labeling by 
scale of the heatma
