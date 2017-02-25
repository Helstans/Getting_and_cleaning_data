library(data.table)
library(dplyr)

wd <- getwd()

url <- 'https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip'
zip <- 'Dataset.zip'
if(!file.exists(zip)) {
  download.file(url,zip)
}
a <- 'UCI HAR Dataset'
if(!file.exists(a)) {
  unzip(zip)
}

#read subjects
dtSubjTrain <- data.table(read.table(file.path(wd, a, 'train', 'subject_train.txt')))
dtSubjTest <- data.table(read.table(file.path(wd, a, 'test', 'subject_test.txt')))
dtSubj <- rbind(dtSubjTrain, dtSubjTest)
names(dtSubj) <- c('Subject')
remove(dtSubjTrain,dtSubjTest)

#read activities
dtActTrain <- data.table(read.table(file.path(wd, a, 'train','Y_train.txt')))
dtActTest <- data.table(read.table(file.path(wd,a,'test','Y_test.txt')))
dtAct <- rbind(dtActTrain,dtActTest)
names(dtAct) <- c('Activity')
remove(dtActTrain,dtActTest)

#merge subject and activity
dtSubj <- cbind(dtSubj,dtAct)
remove(dtAct)

#read feature data
dtTrain <- data.table(read.table(file.path(wd,a,'train','X_train.txt')))
dtTest <- data.table(read.table(file.path(wd,a,'test','X_test.txt')))
dt <- rbind(dtTrain,dtTest)
remove(dtTrain,dtTest)

#merge into one table subject/activity/feature
dt <- cbind(dtSubj,dt)

#set key to subject/activity
setkey(dt,Subject,Activity)
remove(dtSubj)

#read feature names, get only std and mean
dtFeats <- data.table(read.table(file.path(wd,a,'features.txt'))) 
names(dtFeats) <- c('ftNum','ftName')
dtFeats <- dtFeats[grepl("mean\\(\\)|std\\(\\)",ftName)]
dtFeats$ftCode <- paste('V', dtFeats$ftNum, sep = "")

#select only the filtered features (with=FALSE to dynamically pick cols)
dt <- dt[,c(key(dt), dtFeats$ftCode),with=F]

#rename columns
setnames(dt, old=dtFeats$ftCode, new=as.character(dtFeats$ftName))

#read activity names
dtActNames <- data.table(read.table(file.path(wd, a, 'activity_labels.txt')))
names(dtActNames) <- c('Activity','ActivityName')
dt <- merge(dt,dtActNames,by='Activity')
remove(dtActNames)
#add activityname as a key

#merge in ftName

dtTidy <- dt %>% group_by(Subject, ActivityName) %>% summarise_each(funs(mean))

dtTidy$Activity <- NULL

#start seperating out featName column to seperate columns
names(dtTidy) <- gsub('^t', 'time', names(dtTidy))
names(dtTidy) <- gsub('^f', 'frequency', names(dtTidy))
names(dtTidy) <- gsub('Acc', 'Accelerometer', names(dtTidy))
names(dtTidy) <- gsub('Gyro','Gyroscope', names(dtTidy))
names(dtTidy) <- gsub('mean[(][)]','Mean',names(dtTidy))
names(dtTidy) <- gsub('std[(][)]','Std',names(dtTidy))
names(dtTidy) <- gsub('-','',names(dtTidy))


write.table(dtTidy, file.path(wd, 'tidydata.txt'), row.names=FALSE)



