# TREXvis: A randomization-exclusion approach to feature importance

Machine learning approaches are often black boxes that can be challenging to peer into (Kira and Rendell 1992). While a variety of methods exist for the elucidation of feature importance (Guyon and Elisseeff 2003, Yu 2003, Hanchuan, Fuhui, and Ding 2005, Kursa and Rudnicki 2010, Liu and Motoda 1998), many of these are focused on marginal properties of the features themselves, rather than the role of the feature in an actual classifier. In addition, features may have differential utility in different kinds of datasets.  
T-REXvis (Transformed-Randomization EXclusion and visualization) addresses this problem by taking an empirical approach to measuring feature importance, so that we can elucidate the inner workings of an ensemble classifier in different data contexts. So that the results are intuitive and easy to understand, the loss is measured in some performance statistic (e.g., accuracy, specificity, sensitivity, etc.) induced by: 1) randomizing each feature in the classifier, one-by-one; and 2) excluding each feature from the classifier, retraining, and then in the retrained model repeating evaluations of feature importance using (1).  
Once a model is trained, randomizing a particular feature across rows is one way to determine how much that feature contributed to performance, while maintaining the marginal distribution of the predictor. Exclusion and retraining, on the other hand, allows us to understand potential redundancy between features. To allow the joint effect of multiple features to be similarly examined, my implementation of T-REXvis also allows pairs of features of interest to be excluded together. Pseudocode for the basic algorithm is shown in the following figure:  


![Screenshot 2023-07-28 223248](https://github.com/asahaman/TREXvis/assets/7538832/e86e5f13-3037-4300-9917-2f5e3dcdd4b3)  

*T-REXvis returns a ΔU matrix, corresponding to the differences in values of the user statistic, which could be overall accuracy, specificity, sensitivity, or some other function. Rows represent different variations of the model after exclusion and retraining, with the first row representing the original model. Columns correspond to the randomization of each feature (columns) in the context of each model variant (rows).*


Because this is a computationally intensive approach, an automatic pipeline is implemented to run the above described algorithm. The output is visualized in a custom heatmap, where color is used to represent loss in the performance statistic of interest. The implementation of T-REXvis is a wrapper script (Kohavi and John 1997) that makes repeated calls to Weka. The generality of this approach allows it to be used for any classifiers available in Weka. However, for complicated machine learning methods like support vector machines and artificial neutral networks, this is likely to be considerably slower than with random forests. 
The overall pipeline can be run by executing the T-REXvis Perl script for single or pairwise predictor exclusion and randomization.
For example:  

`perl TREX_single_predictor.pl training_data.arff testing_data.arff`  

for single predictor exclusion and randomization. The training and testing data must be in arff format recognizable by Weka. The pairwise predictor exclusion and randomization was not fully automated to avoid unnecessary computations arising from all $`C(N, 2)`$ possible combinations of two predictors. Instead, T-REXvis allows the user to select specific pairs of features for exclusion. For example, the command line for pairwise predictors exclusion and randomization is:  

`perl TREX_pairwise_predictor.pl training_data.arff testing_data.arff X,Y`  

where X,Y indicate the predictors’ numbers that are excluded and separated by comma as a delimiter.
