# TMDL_database

## Creating new TMDL WQ database

### Download and install SQLite3

If SQLite3 is not yet installed on your system, follow directions on this page: http://www.sqlitetutorial.net/download-install-sqlite/

Download and install sqlitebrowser (https://sqlitebrowser.org/) or some other GUI for sqlite. 

### Create new database 

The following method is for creating a new database using sqlitebrowser. You can use an alternate method, including using the command line to create a new database.  

1. Open sqlitebrowser
2. Select New Database
3. Naviagte to folder location, name and save new database 
4. Press cancel on "Edit table definition" window that pops us.


#### Populate new database with database infrastructure. 

The function Create_database() in "Create_database.R" (Note - this might be made into a package in the future) will populate an empty database with an initial table and view structure to house discrete (including continuous data summary statistics) and continuous WQ data. More tables may be needed, depending on project needs.  

Create_database() uses the filename and pathway as an argument and populates the database with the following:

-Tables  
    -AWQMS_data