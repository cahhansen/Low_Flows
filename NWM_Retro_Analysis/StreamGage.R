library(rgdal)
library(rgeos)
library(gdata)

fgdb = "data/NWMLowFlows.gdb"

# List all feature classes in the file geodatabase
subset(ogrDrivers(), grepl("GDB", name))
fc_list = ogrListLayers(fgdb)
print(fc_list)

# Select state of interest
states = readOGR(dsn=fgdb,layer="States")
state_subset = states[which(states$NAME=="California"),]

# Select USGS gages (subset to the state of interest)
usgsgages = readOGR(dsn=fgdb,layer="CAUSGSStreamgages")

# Select NHD stream network (subset to the state of interest)
streams = readOGR(dsn=fgdb,layer="CAnwmchannels")

# Subset the NHD stream network in the state by a user-defined stream order then overlay the streams on the state map
stream_subset = streams[streams$order_ >=1,]

# Subset the above subset to select only the streams in NHD that have a corresponding USGS gage
stream_w_gages = stream_subset[(stream_subset$gages != ""),]
stream_w_gages$gages = factor(stream_w_gages$gages)

# Clean up the subset of gaged streams to ensure there are no NULL data values
stream_w_gages$gages = trim(stream_w_gages$gages, recode.factor = TRUE)
stream_w_gages = stream_w_gages[(stream_w_gages$gages != ""),]

# Create an index data table linking COMID (aka: feature_ID) to GageID to be used in NWM data retrieval
COMID2gage_index = data.frame(stream_subset$feature_id,stream_subset$gages)
names(COMID2gage_index)[1]=paste("COMID")
names(COMID2gage_index)[2]=paste("GageID")

# Create .csv file of COMID2gage_index data frame
write.csv(COMID2gage_index, file = "COMID2gage.csv")

# Create a list of the stream gage IDs that are assimilated to the NHD stream network
library(dataRetrieval)
Gage_list = as.character(stream_subset$gages)

#create a new data frame that will hold the streamflow time series for all gages at a specified time period
Observations = data.frame(Date=seq(as.Date("1993-01-01"),as.Date("2016-10-31"),by=1))

# Loops through the list of gageIDs and appends a new column containing the daily streamflow values for each gageID (the column name is the gageID).
library(dplyr)
for (i in Gage_list){
  dailyq = readNWISdata(sites=i, service="dv", parameterCd="00060", startDate="1993-01-01", endDate="2016-10-31")
  if (nrow(dailyq) > 0){ 
    df = data.frame(Date = as.Date(dailyq$dateTime), Gage_ID = dailyq$X_00060_00003)
    names(df)[ncol(df)] = paste0(i)
    Observations = left_join(Observations, df, by="Date")
  }
  
} 








