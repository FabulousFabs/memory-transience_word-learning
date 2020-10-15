## nonsense simulation to help me think about this stuff

library(dplyr)
library("ggpubr")

# setup
rm(list=ls(all=TRUE));
participants = 20;
items = 20;
F1 = 3;
F2 = 2;
SD = 100;
E = matrix(c(-4, -2.5, -1.5, 1, -1, 0), nrow=F2, ncol=F1, byrow=TRUE);

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
                      RT=rnorm(1, mean=500, sd=SD) + (E[n,k] * rnorm(1, mean=25, sd=5)),
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

# remove parts of the data (unknown items + known speaker same)
data_bkup <- data;
x = which(data$Novelty_Item == 2);
y = which(data[x,]$Novelty_Speaker == 1);
z = which(!(1:(participants*items*F1*F2) %in% y));
data = data_bkup[z,];

# visualise
ggboxplot(data, x = "Novelty_Speaker", y = "RT", color="Novelty_Item")

# analyse
car::leveneTest(RT ~ Novelty_Item * Novelty_Speaker, data=data)
res.aov2 <- aov(RT ~ Novelty_Item * Novelty_Speaker, data=data)
summary(res.aov2)
TukeyHSD(res.aov2, which = "Novelty_Speaker")
TukeyHSD(res.aov2, which = "Novelty_Item")
interaction.plot(data$Novelty_Item, data$Novelty_Speaker, response=data$RT)