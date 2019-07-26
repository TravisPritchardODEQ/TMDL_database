# wqdb

wqdb is an R package containing a series functions to create a SQLite database with table schema that mirrors Oregon DEQ's AWQMS and Stations databases. The package was built to facilitate accessing and archiving water quality data used in various analysis projects after it has been gathered from other sources. SQLite databases are portable and self-contained hence can be saved within the project folder. SQLite database also retain most of the SQL functionality and hence can be accessed and queried using standard scripting.

The database functions use the following R packages:

- DBI
- glue
- RSQLite
- odbc

## Creating a new water quality database

**write_wqdb(db, awqms=NULL, other=NULL, continuous=NULL, stations=NULL, characteristics=NULL)** 

use write_wqdb() to create and/or write to a wqdb formatted SQLite database. If the wqdb database already exists this function will check if the tables exist and create them if not. If a dataframe is passed the data will be written into the tables. Duplicate records are checked and not overwritten.

 1. **db** The path and file name to the new SQLite database to be created.

 2. **stations** Information about monitoring locations. This is intended to be pulled from the Stations database, but the user can add additional records
 
 3. **characteristics** A list of characteristics (parameters). The primary use of this table is to provide the valid values for the Char_Name field in the awqms, other, and continuous tables.  This table is initially populated with the list of characteristics compatible with AWQMS as of 2009/04/25, but the user can add additional entries.  
     
 4. **awqms** This table holds data exported from AWQMS using the AWQMS_data() function from the AWQMS_data package. Note that not all columns from the table exported from AWQMS_data() are brought into this table (information about stations is removed to save on storage space)
 
 5. **other** This table is functionally similar to the 'awqms' table, but is designed to hold water quality data from sources outside of AWQMS.
 
 6. **continuous** This table holds raw continuous data. 
     
The schemas for these tables can be found in **Table_structures.xlsx**.

In addition to these tables, Create_database() also creates 2 data views:

 1. **vw_discrete**
     - This view is a union with 'awqms' and 'other' tables joined with the 'stations' table. This is intended to be the primary view to query against for analysis. 
 2. **vw_continuous**
     - This view joins the 'continuous' table with the 'stations' table. 
    
## Functions

awqms_cols()
char_cols()
cont_cols()
create_wqdb()
query_stations()
read_wqdb()
station_cols()
write_stations()
write_wqdb()


### OPTIONAL - Download and install SQLite3

The required R package dependences have everything you need if working from within R. However, if you want to create, read, or write the SQLite database outside of R using command line or other tools, follow the instructions below.

If SQLite3 is not yet installed on your system, follow these directions:

1. Navigate to the SQLite Downloads page: https://www.sqlite.org/download.html/. 
2. Download the pre-compiled binaries. For example on 64 bit windows it will be something like "sqlite-dll-win64-x64-3280000.zip" and contain files named "sqlite3.dll" and "sqlite3.def".
3. Download the bundle of command-line tools for managing SQLite database files. For example on windows it will be something like "sqlite-tools-win32-x86-3280000.zip". This should inlcude the command-line shell program "sqlite3.exe". 
4. Unzip and save all the files in a folder directory named "sqlite3". On windows the folder will be located at C:\sqlite3.
5. For windows, add C:\sqlite3 to your PATH variable.

Optional:
6. Download and install sqlitebrowser (https://sqlitebrowser.org/) or some other GUI for sqlite.

### Create a new database using command line

Open command line and execute the following:

```> sqlite3 test.db ".databases"```


### Create a new database with sqlitebrowser

The following method is for creating a new database using sqlitebrowser. You can use an alternate method, including using the command line to create a new database.  

1. Open sqlitebrowser
2. Select New Database
3. Navigate to folder location, name and save new database 
4. Press cancel on "Edit table definition" window that pops us.


