
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
        
        if (is.null(temp$data[1][[1]])) stop("No Returned Entities! Check the parameter again!") 
        
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
        
    }
    
    
    
    
}


nowPA <- function(offset = 300){ # default value: 5 minutes
    
    gsub("\\..*","",as.character(now(tzone = "UTC")-offset))
}

# readxl::read_xlsx(path = "./data/secret/key2Yonghun_1010.xlsx",sheet = 2)
# 
# jsonlite::toJSON(readxl::read_xlsx(path = "./data/secret/key2Yonghun_1010.xlsx",sheet = 2))|>
#     charToRaw() |>
#     base64enc::base64encode()|>
#     writeLines("./data/secret/participant.txt")



# Import the API key
# secret <- readLines("./data/secret/secret.txt")
# sensor_idx <- readLines("./data/secret/sensor_idx.txt")
# read_key <- readLines("./data/secret/readkey.txt")

ghtoken <- Sys.getenv("TOKEN_GH")


secret <- Sys.getenv("SECRET")
sensor_idx <- Sys.getenv("SENSOR_IDX")
read_key <- Sys.getenv("READ_KEY")

#jsonlite::read_json("./data/secret/participants.json")


#print(getwd())



tryCatch({
    
    sensor_data <- get_sensor_history(secret = secret,
                                      sensor_idx = sensor_idx,
                                      start_timestamp = nowPA(),
                                      read_key = read_key,
                                      average = 0,
                                      fields ="pa_latency"
                                      )
    
    cat(lubridate::now(tzone = "UTC")|>as.character(),"\n")
    print(sensor_data[,c("date","time")])
    
    #for testing
    msg <- paste0("[Bot] ",nowPA(), " UTC : Warning! Offline Sensor detected! (Sensor Index: ", sensor_idx,")")
    
    
    
}, error = function(e) {
    
    cat("Issuing on GitHub\n")
    #msg <- paste0("[Bot] ",nowPA(), " UTC : Warning! Offline Sensor detected! (Sensor Index: ", sensor_idx,")")

    gh::gh(
        .token = ghtoken,
        endpoint = "POST /repos/YONGHUNI/rougue_PA_detector/issues",
        title = msg,
        body = paste0(nowPA(), "UTC : Warning! Offline Sensor detected!\n (Sensor Index: ", sensor_idx,")\n@YONGHUNI please respond!")
    )
    writeLines(msg, "./msg.txt")
    #write.csv() # for handling multiple sensors
})




