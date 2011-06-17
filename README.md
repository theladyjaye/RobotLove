About
=================
So we wanted a photo booth, but naturally being a developer I wanted it to be something
a bit more special, so I wrote one myself.

Given the location, I was unsure about the stability of my connectivity, so that prompted 2 decisions:

1) I was going to run an agent on one of my cloud servers so I could be assured that at a minimum, I would be 
   able to hit Instagram and save the photos from the event.

2) I was going to use CouchDB to facilitate syncing the data from the server to the desktop agent so I would not
   have to worry about any data syncing issues. After syncing all of the data would be local as well
   so if I lost connectivity for a spell, I should still have plenty of local data to process.

3) The printing device we had our eye on is the Polaroid GL10
   Printer: http://store.polaroid.com/product/0/425422/GL10/_/Instant_Mobile_Printer 
   Paper: http://store.polaroid.com/product/0/0/M340/_/Polaroid_3%22x4%22_ZINK_Paper%26%23174%3B


So, this is still a work in progress, if you run into any issues and need a hand, lemme know.

High Level
-------------
The server agent polls Instagram (see config for setting this interval time) for new photos based on #hashtag or location id. As it encounters new photos it will do 2 things:
1) Save them to disk
2) Save the image data in CouchDB along with some meta information

At the same time, the desktop agent polls the server agent for new photos.  It does this using CouchDB's nifty replication and changes features.
Because of this replication, the data is store locally on the desktop agent, so we have no fears about connectivity during the printing process.
As the desktop agent encounters new photos, it will grab CouchDB documents in groups of 5 and send those sequentially to the printer.
When the queue of 5 is exhausted, the desktop agent will replicate the data from the server agent.  If no new data is present, the 
desktop agent will sleep for a set time (see RobotLove-Config.plist) before checking again.

This process will keep going until you stop it.

Server Agent
=================
The server agent is responsible for querying Instagram, and storing photos on the server's filesystem and into CouchDB.
The server agent can be configured to query Instagram for both a #hashtag and a location id.

See: server-agent/robotlove/config.js

Server Agent Config Properties:
--------------------------------
	module.exports = {
		"interval" : 60000,       // Polling interval, in milliseconds.
		"dropbox"  : "./dropbox", // Where on the server's file system should it store the images it acquires from Instagram.
		"couchdb"  : "robotlove", // database to save data to in couchdb
		"instagram": 
		{
			"api_key"           : "<your api key>", // Instagram API Key
			"location_id"       : "3241884", // Location Id 
			"tag"               : "robotlove2011", // Hash Tag don't need the #
			"location_id_cache" : "__instagram_location", // Filename to store the last location photo id grabbed from Instagram 
			"tag_id_cache"      : "__instagram_tag", // Filename to store the last tag photo id grabbed from Instagram
		}
	}


Software Requirements
------------------------
CouchDB 1.0+
http://couchdb.apache.org/

Node.js 0.4.8+
http://nodejs.org/

Npm (Node Package Manager)
http://npmjs.org/

Request (npm install request)
https://github.com/mikeal/request


Desktop Agent
=================
The desktop agent is responsible for actually printing the photos to your default printer.

Software Requirements
------------------------
OS X 10.6+
Xcode 4.0+

CouchDB 1.0+
http://couchdb.apache.org/

*Xcode Project Dependencies:*
yajl-objc (JSON Parsing Library)
https://github.com/gabriel/yajl-objc

ASIHttpRequest
http://allseeing-i.com/ASIHTTPRequest/

Desktop Agent Properties
------------------------------
RobotLove-Config.plist

<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>local_database</key>
	<string>robotlove2</string>
	<key>remote_database</key>
	<string>robotlove</string> 
	<key>sleep_time</key>
	<integer>15</integer>
</dict>
</plist>

local_database: 
database name the desktop agent will read from

remote_database:
database name the server agent writes to

sleep_time: 
When there is nothing left to do, how many seconds should we wait to  
have the local couchdb instance sync with the sever agent couchdb instance to check for more data

Getting it up and Running
============================

Server Agent
-------------------
The server agent is kicked off by this command:
"node agent.js"

Desktop Agent
-------------------
You will need to install CouchDB on the machine you expect to be responsible for the printing.  

Installing CouchDB on OS X:
http://wiki.apache.org/couchdb/Installing_on_OSX

Open the project in Xcode and configure and edit the RobotLove-Config.plist

local_database  - Name of the CouchDB database that the desktop agent will read from locally.
remote_database - Name of the remote CouchDB database that the server agent is writing to.
sleep_time      - Once all of the photos have printed, how many seconds should we wait to check the server agent for more photos?



TODO
=================
Handle Pagination better on Instagram
