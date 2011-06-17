// Copyright 2011 Adam Venturella
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.


var request          = require("request")
 , couchdb           = require("../couchdb")
 , config            = require("./config")
 , request           = require("request")
 , fs                = require("fs")
 , _last_location_id = "94496471"//null
 , _last_tag_id      = "84808463"//null
 , instagram         = new (require("../instagram/instagram"))(config.instagram.api_key)

var cache_db = new couchdb.client({"database":config.couchb});

function agent()
{
	console.log("[robotlove] running operation");
	check_instagram_location();
	check_instagram_tag();
}

function check_instagram_tag()
{
	console.log("[instagram] checking for new images with tag: \""+ config.instagram.tag + "\"");
	instagram.client.recentMediaForTag(config.instagram.tag, null, instagram_tag_response);
}

function check_instagram_location()
{
	console.log("[instagram] checking for new images for location: \""+ config.instagram.location_id + "\"");
	instagram.client.recentMediaForLocation(config.instagram.location_id, null, instagram_location_response);
}

function instagram_initialize_cache_ids()
{
	try
	{
		console.log("[instagram] initializing instagram cached location id");
		var location_id = fs.readFileSync(config.dropbox + "/" + config.instagram.location_id_cache, "utf8");
		console.log("[instagram] last location id from cache: " + location_id)
		_last_location_id = location_id
	}
	catch(e)
	{ 
		console.log("[instagram] cached location id unavailable")
	}

	try
	{
		console.log("[instagram] initializing instagram cached tag id");
		var tag_id = fs.readFileSync(config.dropbox + "/" + config.instagram.tag_id_cache, "utf8");
		console.log("[instagram] last tag id from cache: " + tag_id)
		_last_tag_id = tag_id
	}
	catch(e)
	{ 
		console.log("[instagram] cached tag id unavailable")
	}
}

function instagram_location_response(ok, response)
{
	if(ok)
	{
		if(response.data.length > 0)
		{
			instagram_process_response(response, "location")
		}
	}
}

function instagram_tag_response(ok, response)
{
	if(ok)
	{
		if(response.data.length > 0)
		{
			instagram_process_response(response, "tag")
		}
	}
}

function instagram_process_response(response, response_type)
{
	var last_id     = response_type == "tag" ? _last_tag_id : _last_location_id;
	var set_last_id = response_type == "tag" ? instagram_set_last_tag_id : instagram_set_last_location_id;
	
	if(last_id != null)
	{
		if(last_id == response.data[0].id)
		{
			console.log("[instagram] " + response_type + " is up to date");
			return;
		}
		else
		{
			console.log("[instagram] " + response_type + " is out of date, syncing");
			
			try
			{
				instagram_save_photos(response, last_id);
			}
			catch(error) { /* no op */}
			
			set_last_id(response.data[0].id)
		}
	}
	else
	{
		set_last_id(response.data[0].id)
		instagram_save_photos(response);
	}
}

function instagram_set_last_location_id(id)
{
	_last_location_id = id;
	
	console.log("[instagram] caching last location id: " + id)
	
	var cache_filename = config.dropbox + "/" + config.instagram.location_id_cache;
	fs.writeFileSync(cache_filename, id, encoding='utf8');
}

function instagram_set_last_tag_id(id)
{
	_last_tag_id = id;
	console.log("[instagram] caching last location tag: " + id)
	
	var cache_filename = config.dropbox + "/" + config.instagram.tag_id_cache;
	fs.writeFileSync(cache_filename, id, encoding='utf8');
}

function instagram_save_photos(response, up_to_id)
{
	response.data.forEach(function(photo)
	{
		if(up_to_id != null && photo.id == up_to_id)
		{
			throw new Error("StopIteration"); // can't break forEach must throw
		}
		
		var image_uri = photo.images.standard_resolution.url;
		var filename  = image_uri.substr(image_uri.lastIndexOf("/") + 1);
		var params    = {"method":"GET",
			             "uri":image_uri};
		
		var req       = request(params);
		var out       = fs.createWriteStream(config.dropbox + "/" + filename, {flags: 'w', encoding: 'binary', mode: 0666});
	
		out.addListener("close", function()
		{
			console.log("[instagram] save complete: " + filename)
			
			// read the file into a buffer for storing in couchdb
			// could probably do this all in 1 operation from the request object, eh
			// it's working now, and I gotta take Lucy out for a walk. Leaving it as it is.
			fs.readFile(config.dropbox + "/" + filename, function (err, data) 
			{
				var record = { "username"      : photo.user.username,
				               "full_name"     : photo.user.full_name,
				               "instagram_url" : photo.images.standard_resolution.url,
				               "instagram_id"  : photo.id,
				               "filename"      : filename,
				               "_attachments":{
								    "photo.jpg":
								    {
								      "content_type":"image\/jpeg",
								      "data": data.toString("base64")
								    }
								  }
				              }
				
				// the Desktop Client will have an instace of couch and sync
				// it will know it's last id and request from changes since that id
				// probably 5 or so.
				// once it goes though those 5, it will store the last id again, and request the 
				// next N changes and so on down the line until there is nothing left
				// While it's processing a queue, it will also tell couchdb to sync
				cache_db.create_document(record, function(data)
				{
					if(data.ok)
					{
						console.log("[couchdb] saved record image" + filename + " with id " + data.id);
					}
					else
					{
						console.log("[couchdb] failed to save record for image " + filename);
					}
				});
			});
			
			// zeromq notify		
		}, false);
		
		console.log("[instagram] saving: " + filename)
		req.pipe(out);
	})
}


//couchdb.set_database("robotlove");
instagram_initialize_cache_ids()
module.exports = agent;