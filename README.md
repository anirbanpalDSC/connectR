# connectR
SQLconnectR is a collection of functions to connect R to different data sources. Long term idea is to convert it in a R package. With various methods of the current solution, user should be able to connect to various SQL data sources e.g. SQL Server using ODBC driver 13 , Azure SQL DB, older flavor of SQL Server, etc. and get data from the sources in the form of R data object, e.g. data frame.

## Getting Started
Currently, the SQLconnectR.R file can be imported to any existing R projects and the functions could be used to create SQL database connection, execute SQL script and get result back in a dplyr dataframe.

### Prerequisite
To execute this project, you will need the following applications -
R - 3.5+
Any R editor, e.g. R Studio, Jupyter or any other notebook
R packages:
`DBI`, `ODBC`, `glue`, `magrittr`, `dplyr`, `stringr`.

### Installing
This particular project requires some dependent packages but the dependency would be mentioned as the part of the function and they should be installed automatically from CRAN as needed.

## Usage
`runSQL(<SQLFilePath>, <ServerName>, <DatabaseName>,glueSQLlist=list(rCnt=<Parameter or R Variable>),)`

## Project Status
Project is completed for the SQL connectivity part. Other connection options can be extended and explored in future.

## Versioning
Git is used for project versioning.

## Authors
Anirban Pal

## Acknowledgements
Hat tip to anyone whose code was used
Inspiration
etc
