
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
        
        if (is.null(temp$data[1][[1]])) stop("No Returned Entities! - Sensor Offline") 
        
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
        stop(paste0("No Returned Entities!","Status code: ",apiResult$status_code,", ",temp$error,": ",temp$description,"\n"))
    }
    
    
    
    
}



checkNconcat <- function(to_be_concat_vector){
    
    if(max(grepl(" ", read_keys, fixed = T))) {
        
        strbuild <- paste("\n",
            deparse1(substitute(to_be_concat_vector)),
            "param error... Should be an R character vector(array)")
        
        stop(strbuild)
        
        
    } else {
        
        return(paste(to_be_concat_vector, collapse = ','))
        
    }
        
    
}



get_sensors_data <- function(fields, location_type = NA, read_keys = NA, show_only = NA, modified_since = NA,
                             max_age = NA, nwlat = NA, nwlng = NA, selat = NA, selng = NA){
    
    require("data.table")
    require("httr")
    
    concat_fields <- checkNconcat(fields)
    concat_read_keys <- checkNconcat(read_keys)
    concat_show_only <- checkNconcat(show_only)
    
     
    
    qlist <-  Filter(Negate(anyNA),list(
        `read_key` = read_key,      # 
        `fields` = concat_fields
    ))
    
    
    # calling an API
    apiResult <- httr::GET( 
        url = paste0("https://api.purpleair.com/v1/sensors/",sensor_idx),
        add_headers(`X-API-Key` = secret),
        query = qlist
    )
    
    
    if (apiResult$status_code == "200"){
        cat("ResultCode OK!\n")
        temp <- rawToChar(apiResult$content)
        Encoding(temp) <- "UTF-8"
        temp <- jsonlite::fromJSON(temp,flatten = T) 
        
        #cat("===============API Result===============\n\n")
        #print(unlist(temp))
        #cat("\n\n===============End of Result===============\n\n")
        
        
        return(temp)
        
        
    }else{
        
        temp <- rawToChar(apiResult$content) |> jsonlite::fromJSON()
        cat(sep = "",
            "Bad Request Exception in / Unexpected Error\n",
            "Status code: ",apiResult$status_code, "\n",
            temp$error,": ",temp$description,"\n"
        )
        
    }
    
}



nowPA <- function(offset = 300){ # default value: 5 minutes
    
    gsub("\\..*","",as.character(now(tzone = "UTC")-offset))
}




 
  # jsonlite::toJSON(readxl::read_xlsx(path = "./data/secret/key2Yonghun_1012.xlsx",sheet = 2))|>
  #     charToRaw() |>
  #     base64enc::base64encode()|>
  #     writeLines("./data/secret/participant.txt")

library("data.table")

if (Sys.info()[[1]]=="Windows") {
    
    # For my Windows Environment
    # Import the API key
    secret <- readLines("./../data/secret/secret.txt")
    sensor_idx <- readLines("./../data/secret/sensor_idx.txt")
    read_key <- readLines("./../data/secret/readkey.txt")
    database <- readLines("./../data/secret/participant.txt") |>
        base64enc::base64decode() |>
        rawToChar() |>
        jsonlite::fromJSON() |>
        as.data.table()
    
} else{
    
    # For github actions Ubuntu env
    
    secret <- Sys.getenv("SECRET")
    database <- Sys.getenv("DATABASE")|>
        base64enc::base64decode() |>
        rawToChar() |>
        jsonlite::fromJSON() |>
        as.data.table()
    
    
    #deprecated
    #ghtoken <- Sys.getenv("TOKEN_GH")
    #sensor_idx <- Sys.getenv("SENSOR_IDX")
    #read_key <- Sys.getenv("READ_KEY")
    
}

rogue_sensors <-  data.table()

# 12 sensors + Dr.Yoo's sensor

for (i in 1:length(database$`sensor index`)) {
    
    cat(paste0("Checking sensor ",i,"...\n","Sensor No. ",database$`sensor index`[i]," / ", database$`station ID`[i],"\n"))
    
    tryCatch({
        
        sensor_data <- get_sensor_history(secret = secret,
                                          sensor_idx = database$`sensor index`[i],
                                          start_timestamp = nowPA(),
                                          read_key = database$`read key`[i],
                                          average = 0,
                                          fields ="pa_latency"
        )
        
        cat(lubridate::now(tzone = "UTC")|>as.character(),"\n")
        print(sensor_data[,c("date","time")])
        cat("\n\n\n")
        
        
    }, error = function(e) {
        
        # for debugging
        cat(paste0("Firing: Sensor No.",database$`sensor index`[i], " malfunctioning!","\n"))
        cat("\n\n\n")
        ######## deprecated
        # gh::gh(
        #     .token = ghtoken,
        #     endpoint = "POST /repos/YONGHUNI/rougue_PA_detector/issues",
        #     title = msg,
        #     body = paste0(nowPA(), "UTC : Warning! Offline Sensor detected!\n (Sensor Index: ", sensor_idx,")\n@YONGHUNI please respond!")
        # )
        
        rogue_sensors <<- cbind(database[i,],e[[1]])|>rbind(rogue_sensors)
        
        
    })
    # https://community.purpleair.com/t/loop-api-calls-for-historical-data/4623#p-7306-avoiding-rate-limiting-6
    # 500 milliseconds:	This will typically be sufficient to avoid rate-limiting in most cases. However, it can still occur, especially when sending many requests in a row.
    Sys.sleep(.5)
}


if (nrow(rogue_sensors)!=0) {
    
    cat("Issuing on Discord\n")
    #msg <- paste0("[Bot] ", 
    #              nowPA(), 
    #              " UTC : Warning! Offline sensors detected! Sensor Index: [",
    #              paste(rogue_sensors$`sensor index`,collapse = "] ["),
    #              "] Please refer to the CSV file attached.")

      msg <- paste0("[Bot] ", 
                  nowPA(), 
                  " UTC : Warning! ", length(rogue_sensors$`sensor index`), 
                    "offline sensors detected! Please refer to the CSV file attached.")

  
    
    writeLines(msg, "./msg")
    fwrite(rogue_sensors,"./list.csv")
    
}
