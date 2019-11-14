library('magrittr')

# Create connection to SQL server
# Supported modules are Azure SQL DB and SQL Server on prem
connectSQL <-
  function(databaseServer = NULL, databaseName = NULL, driver = NULL, newConString = NULL) {
    
    # Check for supported driver
    if (!is.null(driver)) {
      if (!tolower(driver) %in% c("odbc13", "sqlserver")) {
        stop("Only the ODBC 13 SQL SERVER (ODBC13) and SQL Server (SQLServer) drivers are supported.")
      }
    }
    
    # Connectionto Azure SQL database
    AzureSQLDBCon <- paste(
      "Driver={ODBC Driver 13 for SQL Server};",
      "Server=tcp:",
      databaseServer,
      ";port=1433;",
      ";Database=",
      databaseName,
      ";Encrypt=yes;",
      "TrustServerCertificate=no;",
      "Connection Timeout=30;",
      "Authentication=ActiveDirectoryIntegrated",
      sep = ""
    )
    
    # Connection to on prem SQL Server (driver 13)
    OnPremSQLDBCon <- paste(
      "Driver={ODBC Driver 13 for SQL Server}",
      ";Server=",
      databaseServer,
      ";Database=",
      databaseName,
      ";Trusted_Connection=yes;",
      sep = ""
    )
    
    # Connection to on prem SQL Server (older driver)
    LegacySQLDBCon <- paste(
      "DRIVER=",
      "SQL Server",
      ";Database=",
      databaseName,
      ";Server=",
      databaseServer,
      sep = ""
    )
    
    # Create proper connection string
    if (!is.null(newConString)) {
      constr <- newConString
    } else if (endsWith(databaseServer, ".windows.net")) {
      constr <- AzureSQLDBCon
    } else if (!is.null(driver)){
      if (tolower(driver) == "odbc13") {
        constr <- OnPremSQLDBCon
      } else if (tolower(driver) == "sqlserver") {
        constr <- LegacySQLDBCon
      }
    } else {
      constr <- OnPremSQLDBCon
    }
    
    # Return connection string
    return(DBI::dbConnect(odbc::odbc(), .connection_string = constr))
  }

# Create formatted SQL script
createScript <-
  function(sqlScript = NULL,
           databaseServer = NULL,
           databaseName = NULL,
           sqlfilename = NULL,
           glueSQLlist = NULL,
           gluelist = NULL,
           outputfilename = NULL) {
    if (is.null(sqlScript) & is.null(sqlfilename)) {
      stop("Please provide the SQL file name or the SQL script")
    }
    
    if (!is.null(sqlScript) & !is.null(sqlfilename)) {
      stop("Please provide either the SQL file name or the SQL script")
    }
    
    # Create formatted SQL script to pass to connection
    if (!is.null(sqlfilename)) {
      filecon <- file(sqlfilename, "r")
      lines <- readLines(filecon, warn = FALSE)
      close(filecon)
      sqlScript <- paste(lines, collapse = "\n")
    }
    
    # If there are multiple values in filter condition, format them as well
    if (!is.null(gluelist)) {
      nms <- names(gluelist)
      for (i in 1:length(nms))
      {
        sqlScript <-
          gsub(paste("\\{", nms[i], "\\}", sep = ""), gluelist[[nms[i]]], sqlScript)
      }
    }
    
    if (!is.null(glueSQLlist)) {
      if (is.null(databaseServer)) {
        stop(
          "For the SQL list for filter, please include server name"
        )
      }
      
      # Create and manage connection
      con1 <- connectSQL(databaseServer, databaseName)
      on.exit(DBI::dbDisconnect(con1))
      sqlScript <- glue::glue_data_sql(sqlScript, .x = glueSQLlist, .con = con1)
    }
    
    # Append the SQL SET options
    if (!grepl("set nocount on", sqlScript, ignore.case = TRUE)) {
      sqlScript <- paste("SET NOCOUNT ON\n", sqlScript)
    }
    
    if (!grepl("Set ansi_warnings off", sqlScript, ignore.case = TRUE)) {
      sqlScript <- paste("SET ANSI_WARNINGS OFF\n", sqlScript)
    }
    
    if (!is.null(outputfilename)) {
      filecon <- file(outputfilename, "w")
      writeLines(sqlScript, filecon)
      close(filecon)
      return(NULL)
    } else {
      return(sqlScript)
    }
  }

# Execute code in SQL Server
runScriprt <-
  function(sqlScript,
           databaseServer = NULL,
           databaseName = NULL,
           glueSQLlist = NULL,
           gluelist = NULL,
           driver = NULL,
           newConString = NULL,
           newCon = NULL) {
    
    # Add all parameters in the SQL script before sending to database
    sqlScript <-
      createScript(
        sqlScript = sqlScript,
        databaseServer = databaseServer,
        databaseName = databaseName,
        glueSQLlist = glueSQLlist,
        gluelist = gluelist
      )
    
    # Create conection
    if (!is.null(newCon)) {
      con1 <- newCon
    } else {
      con1 <-
        connectSQL(databaseServer, databaseName, driver, newConString)
    }
    
    on.exit(DBI::dbDisconnect(con1))
    response <- DBI::dbGetQuery(con1, sqlScript)
    response <- response %>%
      dplyr::mutate_if(is.character, stringr::str_trim)
    
    return(response)
  }

# Wrapper function to execute SQL
runSQL <-
  function(sqlFileName,
           databaseServer = NULL,
           databaseName = NULL,
           encoding = "",
           glueSQLlist = NULL,
           gluelist = NULL,
           driver = NULL,
           newConString = NULL,
           newCon = NULL) {
    
    filecon <- file(sqlFileName, "r", encoding = encoding)
    lines <- readLines(filecon, warn = FALSE)
    
    sqlcmd <- paste(lines, collapse = "\n")
    on.exit(close(filecon))

    # Execute and get the data back as a data frame
    result <- runScriprt(sqlcmd, 
                           databaseServer, 
                           databaseName, 
                           glueSQLlist,
                           gluelist, 
                           driver, 
                           newConString, 
                           newCon)
    return(result)
  }

# Test execute statement
runSQL(<SQLFilePath>, <ServerName>, <DatabaseName>,glueSQLlist=list(rCnt=<Parameter or R Variable>),)
