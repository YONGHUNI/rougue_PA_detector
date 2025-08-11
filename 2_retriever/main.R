

# Get Sensor History
## https://api.purpleair.com/#api-sensors-get-sensor-history

get_sensor_history <- function(secret, sensor_idx, read_key = NA, privacy = NA,
                               start_timestamp = NA, end_timestamp = NA, average = NA,
                               fields ){
    
    require("data.table")
    require("httr")
    require("lubridate")
    
    
    concat_fields <- paste(fields, collapse = ',')
    
    if(grepl(" ", concat_fields, fixed = T)) stop("Field param error...\n Should be an R character vector(array)")
    
    
    parse_date_time(start_timestamp, orders = "%Y-%m-%d %H:%M:%S", exact = TRUE) |> as.integer() -> stime
    parse_date_time(end_timestamp, orders = "%Y-%m-%d %H:%M:%S", exact = TRUE) |> as.integer() -> etime
    
    if (etime-stime <= seconds(days(29))) {                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
        
        
        qlist <-  Filter(Negate(anyNA),list(
            `read_key` = read_key,      # 
            `privacy` = privacy,  # 
            `start_timestamp` = stime,
            `end_timestamp` = etime,
            `average` = average,
            `fields` = concat_fields
        ))
        
        
        # calling an API
        apiResult <- httr::GET( 
            url = paste0("https://api.purpleair.com/v1/sensors/",sensor_idx,"/history"),
            add_headers(`X-API-Key` = secret),
            query = qlist
        )
        
        
        if (apiResult$status_code == "200"){
            cat("ResultCode OK!\n")
            temp <- rawToChar(apiResult$content)
            Encoding(temp) <- "UTF-8"
            temp <- jsonlite::fromJSON(temp)
            
            
            result <- temp$data |> as.data.table() |> `colnames<-`(temp$fields)
            
            
            result[, c("date","time") := data.table::IDateTime(as.POSIXlt(time_stamp,tz = "UTC"))] |>
                setorderv( c("date","time"))
            
            
            return(result)
            
            
        }else{
            
            temp <- rawToChar(apiResult$content) |> jsonlite::fromJSON()
            cat(sep = "",
                "Bad Request Exception in / Unexpected Error\n",
                "Status code: ",apiResult$status_code, "\n",
                temp$error,": ",temp$description,"\n"
            )
            #stop(paste0("No Returned Entities!","Status code: ",apiResult$status_code,", ",temp$error,": ",temp$description,"\n"))
        } 
        
        
    } else {
        
        ddiff <- as.numeric(as_datetime(end_timestamp) - as_datetime(start_timestamp))
        
        num_of_loop <- ceiling(ddiff/29)
        
        bind <- data.table()
        
        for (i in 1:num_of_loop) {
            
            if (i==num_of_loop) {
                
                etime <- as.integer(parse_date_time(end_timestamp, orders = "%Y-%m-%d %H:%M:%S", exact = TRUE))
                
            } else{
                
                etime <- as.numeric(stime + seconds(days(29)))
                
            }
            
            
            qlist <-  Filter(Negate(anyNA),list(
                `read_key` = read_key,      # 
                `privacy` = privacy,  # 
                `start_timestamp` = stime,
                `end_timestamp` = etime,
                `average` = average,
                `fields` = concat_fields
            ))
            
            
            # calling an API
            apiResult <- httr::GET( 
                url = paste0("https://api.purpleair.com/v1/sensors/",sensor_idx,"/history"),
                add_headers(`X-API-Key` = secret),
                query = qlist
            )
            Sys.sleep(1)
            
            if (apiResult$status_code == "200"){
                cat("ResultCode OK!\n")
                temp <- rawToChar(apiResult$content)
                Encoding(temp) <- "UTF-8"
                temp <- jsonlite::fromJSON(temp)
                
                print(dim(temp$data))
                
                stime <- as.numeric(etime + 1) # adding 1 second to avoid the overlap
                if (is.null(temp$data[1][[1]])) next 
                
                try(bind <- rbind(bind,as.data.table(temp$data)))
                
                print(dim(bind))
                
            }else{
                
                temp <- rawToChar(apiResult$content) |> jsonlite::fromJSON()
                cat(sep = "",
                    "Bad Request Exception in / Unexpected Error\n",
                    "Status code: ",apiResult$status_code, "\n",
                    temp$error,": ",temp$description,"\n"
                )
                #stop(paste0("No Returned Entities!","Status code: ",apiResult$status_code,", ",temp$error,": ",temp$description,"\n"))
            } 
            
            
            
        }
        
        result <- bind |> `colnames<-`(temp$fields)
        
        
        result[, c("date","time") := data.table::IDateTime(as.POSIXlt(time_stamp,tz = "UTC"))] |>
            setorderv( c("date","time"))
        
        return(result)
        
    }
    
    
}




library("data.table")

if (Sys.info()[[1]]=="Windows") {
    
    # For my Windows Environment
    # Import the API key
    secret <- readLines("./../data/secret/secret.txt")
    #sensor_idx <- readLines("./data/secret/sensor_idx.txt")
    #read_key <- readLines("./data/secret/readkey.txt")
    # database <- readLines("./data/secret/participant.txt") |>
    #     base64enc::base64decode() |>
    #     rawToChar() |>
    #     jsonlite::fromJSON() |>
    #     as.data.table()
    confidential <- readxl::read_xlsx("./../data/secret/key2Yonghun_3_24_25.xlsx") |> as.data.table()
    confidential[,`sensor index`:=as.character(`sensor index`)]
    
} else{
    
    # For github actions Ubuntu env
    secret <- Sys.getenv("SECRET")
    confidential <- Sys.getenv("DATABASE") |>
         base64enc::base64decode() |>
         rawToChar() |>
         jsonlite::fromJSON() |>
         as.data.table()
    confidential[,`sensor index`:=as.character(`sensor index`)][
    ,`start date`:=mdy(`start date`)]
    
    
    # DB credentials
    db_host <- Sys.getenv("DB_HOST")
    db_name <- Sys.getenv("DB_NAME")
    db_password <- Sys.getenv("DB_PASSWORD")
    db_port <- Sys.getenv("DB_PORT")
    db_user <- Sys.getenv("DB_USER")
    
    
}







# read data
#sensors <- fread("./data/output/2025-02-06_UTC_PA.csv")[,time:=as.ITime(time)]


library(DBI)
library(RPostgres)
library(lubridate)

cat("trying to make a conn with DB\n")
con <- DBI::dbConnect(RPostgres::Postgres(), dbname = db_name, 
                      host = db_host, port = db_port, user = db_user, 
                      password = db_password)

cat("connected!\n")



#cat("fetching data from DB DB\n")
#sensors <- dbReadTable(con, "Purple_Air") |> as.data.table()
#cat("fetched!\n")


variables <- c("humidity","temperature","pressure","voc","pm1.0_atm","pm2.5_atm","pm2.5_cf_1","pm10.0_atm"  ,"pm10.0_cf_1")


# var_order <- names(sensors)
# variables <- var_order[2:10]


#sensors[,key:=as_datetime(time_stamp)]
#sensors[,.(latest=max(key)),by ="sensor_index"]

cat("fetching data from DB DB\n")
cat("getting last observations from each sensor\n")
# last observations

query <- "
  SELECT sensor_index, MAX(time_stamp) AS latest
  FROM \"Purple_Air\"
  GROUP BY sensor_index
"

lastobs <- dbGetQuery(con, query) |> as.data.table() |>
    _[,latest:=as_datetime(latest)]#sensors[,.(latest=max(key)),by ="sensor_index"]
cat("fetched!\n")

setnames(confidential,names(confidential),c("Device_ID","read_key","sensor_index","start_date","station_ID","participant_name", "zipcode"))

confidential <- merge.data.table(lastobs,confidential, all.y = T)



cat("doing loops for new observations\n")
sensors_new <-  data.table()

# fetch data from the sensors with the last observation date
#stime <- "2024-11-10 00:00:00" # stime will be the `lastobs`
etime <- format(as_datetime(now(tzone = "UTC")), "%Y-%m-%d %H:%M:%S")




for (i in 1:length(confidential$`sensor_index`)) {
    
    cat("fetching data from ",confidential$`sensor_index`[i],"...\n")
  
    stime = ifelse(is.na(confidential$`latest`[i]),
                   yes =  format(as_datetime(confidential$start_date[i]),
                                 format = "%Y-%m-%d 00:00:00"),
                   no =  format(confidential$`latest`[i]+1800,
                                format = "%Y-%m-%d %H:%M:%S"))
    
    if(difftime(as_datetime(etime),as_datetime(stime),units = "hours") < 1.) {
      
      cat("\n time diff less then 1 hour... skipping data fetch for this sensor\n\n\n\n")
      next
    }
    
    tryCatch({
        
        cat("is the start date",str(ifelse(is.na(confidential$`latest`[i]),
                   yes =  format(as_datetime(confidential$start_date[i]),
                                 format = "%Y-%m-%d %H:%M:%S"),
                   no =  format(confidential$`latest`[i]+1800,
                                format = "%Y-%m-%d %H:%M:%S"))),"\n")
        


        
        

        
        
        sensor_data <- get_sensor_history(secret = secret,
                                          sensor_idx = confidential$`sensor_index`[i],
                                          start_timestamp = stime,
                                          end_timestamp = etime,
                                          read_key = confidential$`read_key`[i],
                                          average = 30, # 30min
                                          fields = variables
        )
        
        sensor_data[,names(confidential):= as.list(as.vector(confidential[i], mode = "character"))]
        sensors_new <<- rbind(sensor_data,sensors_new)
        
        cat("fetching data from ",confidential$`sensor_index`[i],"was successful \n\n\n\n ")
        
        
    }, error = function(e) {
        
        # for debugging
        cat(paste0("Error in ",confidential$`sensor_index`[i],"\n"))
        print(e)
        cat("\n\n\n\n")
        
        
    })
    Sys.sleep(1) # for preventing API call limit from exceeding
}

cat("fetched new observations\n")
cat(paste("shape of fetched data: (",paste(dim(sensors_new),collapse = ", ")),")\n")


if (dim(sensors_new)[1]>1) {
    cat("testing if the data is valid\n")
    variables_old_head <- dbGetQuery(con, "SELECT * FROM \"Purple_Air\" LIMIT 5;")
    
    variables_old <- names(variables_old_head)
    
    
    sensors_new <- sensors_new[,.SD,.SDcols = !"latest"][,.SD, .SDcols = variables_old]
    
    
    
    
    
    rbind(variables_old_head,sensors_new)|>  summary()
    rbind(variables_old_head,sensors_new)|>  dim()
    cat("test done!\n")
    
    
    cat("Appending the data into DB\n")
    dbWriteTable(con,"Purple_Air",sensors_new, append = TRUE)
    cat("Done!\n")
} else {
  
  cat("no data to be append!\n")
  
}




cat("DB connection cleanup\n")
DBI::dbDisconnect(con)



