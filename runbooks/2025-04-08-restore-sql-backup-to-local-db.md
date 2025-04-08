To restore a backed up version of the production database locally:

*This assumes you have created a backup using a procedure like [this](2022-10-29-prod-db-backup.md):


1.  Open the exported file in a text editor and, if necessary, change the name of the database in the Export to match the name of your local database (ex. change "kgcash" to "kgcash_dev") in both the "CREATE DATABASE" and "use \[database\]" SQL statements near the top of the file.
2.  Open DBeaver
3.  Connect to your local database and select the database that you would like to run the SQL against
4.  Choose **File > Open**
5.  In the file selection window, select the file that contains export file
6.  Click **OK**
7.  Choose **SQL Editor > Execute SQL Script**
8.  If prompted with a dialog that asks **Do you want to disable result set fetching for this script execution?**, optionally select the checkbox not to show the dialog again, and then click **Yes**

The SQL script should now run.

If the script runs successfully, your product database has now been updated with the data in the SQL backup.