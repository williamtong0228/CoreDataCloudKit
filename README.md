# CoreDataCloudKit

Learning how to use CloudKit together with CoreData to store cloud data into local storage, following Apple's instruction 
"Maintaining a Local Cache of CloudKit Records".

The "fetchChange", "fetchDatabaseChange" and "fetchZoneChange" methods in the Viewcontroller should be extracted into a
new class for readibility.

I didn't do error handling in this project but it will not work if your network connection is bad. You have to add error handling codes when merging it into your project. 
