################################
# Load libraries
################################

library(tuneR)
library(seewave)
library(neuralnet)
library(pROC)
options(warn = -1)

################################
# Set constants
################################

COMPUTE_MFFC <- FALSE
DATA_PATH <- "./audio_recordings/"

################################
# Load annotations
################################

info <- read.table("annotations.csv",
                sep = ",",
                header = TRUE)
n <- nrow(info)

##############################
# MFCC
##############################

if (COMPUTE_MFFC == FALSE) {
  ## if the MFFC is already computed
  mel <- readRDS("mfcc.rds")
} else {
  wl <- 512   # fft length
  ncep <- 26  # number of MFCC
  mel <- matrix(rep(NA, wl / 2), nrow = n, ncol = ncep)
  
  for(i in 1:n){
    
    # extract the full path to the audio file
    filename <- paste(DATA_PATH, info$filename[i], sep = "/")
    # read the audio file
    s <- readWave(filename)
    # get the sampling rate
    sr <- s@samp.rate
    # delete the DC offset
    s <- rmoffset(s, output = "Wave")
    
    # Compute "ncep" MFFC
    mfcc <- melfcc(s,
                   sr = sr,
                   wintime = wl / sr,
                   hoptime = wl / sr,
                   numcep = ncep,
                   nbands = ncep * 2,
                   fbtype = "htkmel",
                   dcttype = "t3",
                   htklifter = TRUE,
                   lifterexp = ncep - 1,
                   frames_in_rows = TRUE,
                   spec_out = FALSE)
    
    # compute the mean over the whole signal
    mel[i, ] <- apply(mfcc, MARGIN = 2, FUN = mean)
    
    # release the memory
    rm(s)
    # print message
    print(paste(filename, " computing MFFC ---> Done"))
  }
  
  # Save the variable
  saveRDS(mel, file="mfcc.rds")
  
}

# plot all MFCC on a single plot
matplot(t(mel), type = "l", col = info$plane + 1, lty = 1)

##############################
# TRAIN THE ANN MODEL
##############################

# set the seed for reproducibility
set.seed(1234)

# set the confidence threshold to decide
# if the label is 0 or 1 for each label
confidence_threshold <- 0.5

# Target data
target <- cbind(info$plane, info$wind, info$rain, info$biophony, info$silence)
colnames(target) <- c("plane", "wind", "rain", "biophony", "silence")

# Input data
input <- mel
colnames(input) <- seq_len(ncol(input))

# Scaling of the input data
input <- scale(input)

# combine target and input to create the dataset
dataset <- data.frame(target, input)
dataset <- na.omit(dataset) ## remove NA

# split the dataset into training dataset (80%) and test dataset (20%)
index <- sample(seq_len(nrow(dataset)), round(0.80 * nrow(dataset)))
training <- dataset[index, ]
test <- dataset[-index, ]

# ANN on mfcc
ann <- neuralnet(plane+wind+rain+biophony+silence~X1+X2+X3+X4+X5+X6+X7+X8+X9+X10+X11+X12+X13+X12+X13+X14+X15+X16+X17+X18+X19+X20+X21+X22+X23+X24+X25+X26,
                 data = training,
                 hidden = c(5),
                 linear.output = FALSE,
                 act.fct = "logistic",
                 threshold = 0.1 # default is 0.01
)

## predict on validation
pred <- predict(ann, test)

# convert the result into dataframe
pred <- data.frame(pred)
colnames(pred) <- colnames(target)

##############################
# DISPLAY THE ROC CURVES
##############################

# ouput initialization
roc_curves <- list()

for (class_name in colnames(target)) {
  
  # Extract predicted probabilities for the current class
  predicted_probs <- pred[[class_name]]
  
  # True labels for the current class
  true_labels <- test[[class_name]]
  
  # Compute ROC curve
  roc_curves[[class_name]] <- roc(true_labels, predicted_probs)
  
  # Plot ROC curve for each class for the last training dataset
  plot(roc_curves[[class_name]],
       main = paste("ROC Curve for", class_name),
       col = "blue",
       legacy.axes = TRUE)
}

##############################
# DISPLAY THE SCORES
##############################

# ouput initialization
auc_values <- matrix(NA, nrow = 1, ncol = ncol(target))
accuracy <- matrix(NA, nrow = 1, ncol = ncol(target))
recall  <- matrix(NA, nrow = 1, ncol =  ncol(target))
precision <- matrix(NA, nrow = 1, ncol = ncol(target))
fpr <- matrix(NA, nrow = 1, ncol = ncol(target))
tpr <- matrix(NA, nrow = 1, ncol = ncol(target))

colnames(auc_values) <- colnames(target)
colnames(accuracy) <- colnames(target)
colnames(recall) <- colnames(target)
colnames(precision) <- colnames(target)
colnames(fpr) <- colnames(target)
colnames(tpr) <- colnames(target)

for (class_name in colnames(target)) {
  
  # Extract predicted probabilities for the current class
  predicted_probs <- pred[[class_name]]
  
  # True labels for the current class
  true_labels <- test[[class_name]]
  
  # Compute the AUC
  auc_values[[class_name]] <- auc(roc(true_labels, predicted_probs))
  
  # confusion matrix
  pred[[class_name]][pred[[class_name]] > confidence_threshold]  <- 1
  pred[[class_name]][pred[[class_name]] <= confidence_threshold] <- 0
  
  tab <- table(test[[class_name]], pred[[class_name]])
  
  tp <- tab[1, 1]
  fp <- tab[2, 1]
  tn <- tab[2, 2]
  fn <- tab[1, 2]
  
  # accuracy, recall and precision for each class
  accuracy[[class_name]]  <- 100 * (tp + tn) / (tp + tn + fp + fn)
  recall[[class_name]]    <- 100 * tp / (tp + fn)
  precision[[class_name]] <- 100 * tp / (tp + fp)
  tpr[[class_name]]       <- recall[[class_name]]
  fpr[[class_name]]       <- 100 * fp / (tp + fn)
  
  # print scores
  print(paste("SCORES for",   class_name,
              "AUC",          auc_values[[class_name]],
              "accuracy",     accuracy[[class_name]],
              "recall",       recall[[class_name]],
              "precision",    precision[[class_name]],
              "TPR",          tpr[[class_name]],
              "FPR",          fpr[[class_name]]))
}

