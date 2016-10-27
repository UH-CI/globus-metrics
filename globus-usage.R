#!/usr/bin/env Rscript
library("optparse")
library("datasets")
library("base")
library("utils")
library("methods")
library("stats")
library("dplyr")
options( java.parameters = "-Xmx4g" )
library("xlsx")

option_list = list(
  make_option(c("-f", "--file"), type="character", default=NA, help="globus usage tranger file name", metavar="character"),
  make_option(c("-o", "--out"), type="character", default="out.xlsx", help="output file name [default= %default]", metavar="character"),
  make_option(c("-s", "--start"), type="character", default=NA, help="the start date for globus transfers for the report (YYYY-MM-DD)", metavar="character"),
  make_option(c("-e", "--end"), type="character", default=NA, help="the end date for globus transfers for the report (YYYY-MM-DD)", metavar="character")
); 

#option_list = list(
#  make_option(c("-f", "--file"), type="character", default="Globus_Usage_Transfer_Detail.csv", help="globus usage tranger file name", metavar="character"),
#  make_option(c("-o", "--out"), type="character", default="temp_out.xslx", help="output file name [default= %default]", metavar="character"),
#  make_option(c("-s", "--start"), type="character", default="2015-10-01", help="the start date for globus transfers for the report (YYYY-MM-DD)", metavar="character"),
#  make_option(c("-e", "--end"), type="character", default="2016-09-30", help="the end date for globus transfers for the report (YYYY-MM-DD)", metavar="character")
#); 

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);
# check if input file is provided
if (is.na(opt$file)) {
  stop("the globus transfer usage file parameter must be provided. See script usage (--help)")
}
globusfile <- opt$file
outfile <- opt$out

# check start date is provided
if (is.na(opt$start)) {
  stop("start date parameter must be provided. See script usage (--help)")
}
startdate <- as.POSIXct(strptime(paste(opt$start,"00:00:00"),"%Y-%m-%d %H:%M:%S"))
# check end date is provided
if (is.na(opt$end)) {
  stop("end date parameter must be provided. See script usage (--help)")
}
enddate <- as.POSIXct(strptime(paste(opt$end,"23:59:59"),"%Y-%m-%d %H:%M:%S"))

#read csv file with globus usage data
data <- read.csv(file=globusfile,sep=',',header=TRUE)

#convert completion time columns to a datetime format for filtering and sorting
data$completion_time <- as.POSIXct(paste(data$completion_time), format="%Y-%m-%d %H:%M:%S")

#filter the data by date and successful transfers
#gtdataset <- filter(data, data$completion_time > startdate)
#rufdataset <- filter(gtdataset, gtdataset$completion_time < enddate)
#dataset <- filter(rufdataset, rufdataset$status == "SUCCEEDED")
dataset <- subset(data, data$completion_time > startdate & data$completion_time <= enddate & data$status == "SUCCEEDED")
#order by completion datetime
orddataset <- dataset[order(dataset$completion_time),]

#get unique users
uniqusers <- as.data.frame(unique(orddataset$user_name))

#get unique endpoint sources
uniqsources <- as.data.frame(unique(orddataset$source_endpoint))

#get unique endpoint destinations
uniqdests <- as.data.frame(unique(orddataset$destination_endpoint))

#get total files transfered
totalfilestransfered <- sum(orddataset$successful)

#get total transfer time 
totaltransfertime <- sum(orddataset$successful)
totaltransferdays <- totaltransfertime/60/60/24

#calculate and store transfer rate
orddataset$transfer_rate <- with(orddataset, orddataset$bytes_transferred/orddataset$duration)
orddataset$transfer_rate_mbps <- with(orddataset, orddataset$transfer_rate/1000/1000*8)

transfermetrics <- data.frame("total_files_transfered" = totalfilestransfered, "total_transfer_time(sec)"=totaltransfertime,"total_transfer_time(days)"=totaltransferdays)

transfermetrics$unique_users <- count(uniqusers)
transfermetrics$unique_sources <- count(uniqsources)
transfermetrics$unique_destinations <- count(uniqdests)
transfermetrics$max_transfer_rate <- max(orddataset$transfer_rate_mbps)
transfermetrics$mean_transfer_rate <- mean(orddataset$transfer_rate_mbps)
transfermetrics$total_data_transfered_tb <- sum(orddataset$bytes_transferred)/1000/1000/1000/1000

transfermetrics$gt1gbps <- count(filter(orddataset, transfer_rate_mbps >= 1000))
transfermetrics$gt500mbpsls1gbps <- count(subset(orddataset, transfer_rate_mbps >= 500 & transfer_rate_mbps < 1000))
transfermetrics$gt250mbpsls500mbps <- count(subset(orddataset, transfer_rate_mbps >= 250 & transfer_rate_mbps < 500))
transfermetrics$gt50mbpsls250mbps <- count(subset(orddataset, transfer_rate_mbps >= 50 & transfer_rate_mbps < 250))
transfermetrics$ls50mbps <- count(filter(orddataset, transfer_rate_mbps < 50))

userdatametrics <-as.data.frame(orddataset %>% 
                                  group_by(user_name) %>%                            # multiple group columns
                                  summarise(total_bytes_transfered = sum(bytes_transferred),total_gbs_transfered= sum(bytes_transferred)/1000/1000/1000,files_successful = sum(successful), min_transfer_rate_mbps = min(transfer_rate_mbps), mean_transfer_rate_mbps = mean(transfer_rate_mbps), max_transfer_rate_mbps = max(transfer_rate_mbps)))  # multiple summary columns

#write dataframe to csv file
#write.csv(orddataset, file = outfile,row.names=FALSE)

#write xlsx file
write.xlsx(orddataset, file=outfile, sheetName="transfer-data")
write.xlsx(uniqusers, file=outfile, sheetName="unique-users", append=TRUE)
write.xlsx(uniqsources, file=outfile, sheetName="unique-sources", append=TRUE)
write.xlsx(uniqdests, file=outfile, sheetName="unique-destinations", append=TRUE)
write.xlsx(userdatametrics, file=outfile, sheetName="user-data-metrics", append=TRUE)
write.xlsx(transfermetrics, file=outfile, sheetName="transfer-metrics", append=TRUE)

