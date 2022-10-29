To move a copy of the production database to your development environment:

1. Login to Google Cloud Console
2. From the main menu choose **SQL**
3. Select the database instance that contains the database you'd like to copy. This will take you to the **Overview** page.
4. Choose **Export** on the top nav. This will take you to the **Export data to Cloud Storage** page.
5. In the **Source** section, under *File Format*, select **SQL**.
6. Under *Data to Export* select **One or more databases in this instance**.
7. In the *Databases* drop down, select the database you would like to export.
8. In the **Destination** section, click *Browse* to choose the Cloud Storage location where you would like to put the export.
9. Click the **Export** button.
10. Navigate to the Cloud Storage bucket to which you saved the Export.
11. Download the Export to your local machine
12. Open the exported file and, if necessary, change the name of the database in the Export to match the name of your local database (ex. change "kgcash" to "kgcash_dev") in both the "CREATE DATABASE" and "use \[database\]" SQL statements near the top of the file.
13. Open SequelPro
14. Connect to your local database
15. Choose **File > Import**
16. In the file selection window, select the file that contains your downloaded export
17. Click **OK**

Your product database has now been copied to your local development environment.