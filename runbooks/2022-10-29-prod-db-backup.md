To create a backup of the production database:

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

You now have a local SQL script which constitues local backup of your database.

