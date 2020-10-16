## nonsense simulation to help me think about this stuff

# setup
rm(list=ls(all=TRUE));

library(dplyr)
library("ggpubr")

simulate_data <- function(participants, items, F1, F2, E, Incomplete=FALSE) {
  data <- data.frame(Index=integer(),
                     Participant=integer(),
                     Item=integer(),
                     RT=double(),
                     Novelty_Speaker=factor(),
                     Novelty_Item=factor(),
                     stringsAsFactors=FALSE);
  
  index = 1;
  for (i in 1:participants) {
    for (j in 1:items) {
      for (k in 1:F1) {
        for (n in 1:F2) {
          entry <- list(Index=index,
                        Participant=i,
                        Item=j,
                        RT=rnorm(1, mean=500, sd=SD) + (E[n,k] * rnorm(1, mean=15, sd=5)),
                        Novelty_Speaker=k,
                        Novelty_Item=n);
          data = rbind(data, entry, stringsAsFactors=FALSE);
          index = index + 1;
        }
      }
    }
  }
  
  levels(data$Novelty_Speaker) = gl(3, 1, length=3, labels=c("F_O", "F_N", "N"));
  levels(data$Novelty_Item) = gl(2, 1, length=2, labels=c("K", "U"))
  data$Novelty_Speaker = factor(data$Novelty_Speaker);
  data$Novelty_Item = factor(data$Novelty_Item);
  
  if (Incomplete == TRUE) {
    # remove parts of the data (unknown items + known speaker same)
    data_bkup <- data;
    x = which(data$Novelty_Item == 2);
    y = which(data[x,]$Novelty_Speaker == 1);
    z = which(!(1:(participants*items*F1*F2) %in% y));
    data = data_bkup[z,];
  }
  
  return(data);
}

simulations = 1000;
participants = 34;
items = 20;
F1 = 3;
F2 = 2;
SD = 100;
alpha = 0.05;
E = matrix(c(-2, -1.5, -1, 0, -1, 0), nrow=F2, ncol=F1, byrow=TRUE);

P_Novelty_Item = 0;
P_Novelty_Speaker = 0;
P_Interaction = 0;

for (x in 1:simulations) {
  print(x);
  data <- simulate_data(participants, items, F1, F2, E, Incomplete=TRUE);
  resaov <- aov(RT ~ Novelty_Item * Novelty_Speaker, data=data);
  sumaov <- summary(resaov);
  P_Novelty_Item = P_Novelty_Item + (if (sumaov[[1]][["Pr(>F)"]][1] <= alpha) 1 else 0);
  P_Novelty_Speaker = P_Novelty_Speaker + (if (sumaov[[1]][["Pr(>F)"]][2] <= alpha) 1 else 0);
  P_Interaction = P_Interaction + (if (sumaov[[1]][["Pr(>F)"]][3] <= alpha) 1 else 0);
}

P_Novelty_Item / simulations # true positives for novelty item
P_Novelty_Speaker / simulations # true postiives for novelty speaker
P_Interaction / simulations # true positive interactions

