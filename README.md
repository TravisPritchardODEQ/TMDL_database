# TMDL_database

To use the import functions, you need ODBC connections to AWQMS and to Stations. 

The database functions uses the following packages:

- DBI
- glue
- RSQLite
- odbc

## Creating new TMDL WQ database

### Download and install SQLite3

If SQLite3 is not yet installed on your system, follow these directions:

1. Navigate to the SQLite Downloads page: https://www.sqlite.org/download.html/. 
2. Download the pre-compiled binaries. For example on 64 bit windows it will be something like "sqlite-dll-win64-x64-3280000.zip" and contain files named "sqlite3.dll" and "sqlite3.def".
3. Download the bundle of command-line tools for managing SQLite database files. For example on windows it will be something like "sqlite-tools-win32-x86-3280000.zip". This should inlcude the command-line shell program "sqlite3.exe". 
4. Unzip and save all the files in a folder directory named "sqlite3". On windows the folder will be located at C:\sqlite3.
5. For windows, add C:\sqlite3 to your PATH variable.

Optional:
6. Download and install sqlitebrowser (https://sqlitebrowser.org/) or some other GUI for sqlite. 


### Create a new database

Open command line and execute the following:

```> sqlite3 test.db ".databases"```


### Create a new database with sqlitebrowser

The following method is for creating a new database using sqlitebrowser. You can use an alternate method, including using the command line to create a new database.  

1. Open sqlitebrowser
2. Select New Database
3. Navigate to folder location, name and save new database 
4. Press cancel on "Edit table definition" window that pops us.


### Populate new database with database infrastructure. 

The function Create_database() in "Create_database.R" (Note - this might be made into a package in the future) will populate an empty database with an initial table and view structure to house discrete (including continuous data summary statistics) and continuous WQ data. More tables may be needed, depending on project needs.  

**Create_database()** uses the file name and pathway as an argument and populates the database with the following:

 1. **Stations**
     - Information about monitoring locations. This is intended to be pulled from the Stations database, but the user can add additional records
 2. **Characteristics**
     - A list of characteristics (parameters). The primary use of this table is to provide the valid values for the Char_Name field in AWQMS_data, Other_Data, and continuous_data tables.  This table is initially populated with the list of characteristics compatible with AWQMS as of 2009/04/25, but the user can add additional entries.  
 3. **AWQMS_data**
     - This table holds data exported from AWQMS using the AWQMS_data() function from the AWQMS_data package. Note that not all columns from the table exported from AWQMS_data() are brought into this table (information about stations is removed to save on storage space)
 4. **Other_data**
    - This table is functionally similar to the AWQMS_data table, but is designed to hold WQ data from sources outside of AWQMS_data
 5. **continuous_data**
     - This table hold raw continuous data. 
     
The schemas for these tables can be found in **Table_structures.xlsx**.

In addition to these tables, Create_database() also creates 2 data views:

 1. **vw_Data_all**
     - This view is a union with AWQMS_data and Other_data joined with the Stations table. This is intended to be the primary view to query against for analysis. 
 2. **vw_cont_data**
     - This view joins the continuous_data table with the Stations table. 
     
### Populate database with data

#### Functions

**insert_stations_db()**  
The function insert_stations_db() will take a vector of MLocIDs and query data from the Stations database. This query is then loaded in the Stations table in the specified SQLite database. Note - trying to load in duplicate values will cause an error.

**import_AWQMS_data()** 
The function import_AWQMS_data() will take a dataframe returned by AWQMS_data() in the AWQMS_data package and insert it into the AWQMS_data table. Note - trying to load in duplicate records will cause an error.  

#### Templates

Some templates to help with loading into the database can be found in the templates folder. Code to insert the results into the database still needs to be written, but will likely look a lot like import_AWQMS_data().
