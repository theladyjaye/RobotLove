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

var request   = require("request");
var defaults  = {"host"    : "127.0.0.1",
                 "port"    : "5984"}

exports.client = function(options)
{
	return new CouchDB(options);
}

function CouchDB(options)
{
	this._host     = (typeof options.host == "undefined")     ? defaults.host : options.host;
	this._port     = (typeof options.port == "undefined")     ? defaults.port : options.port;
	this._database = (typeof options.database == "undefined") ? null          : options.database;
	this._scheme   = "http://";
}


CouchDB.prototype.create_document = function(id, document, callback)
{
	if(this._database == null) throw new Error("[couchdb] cannot create document, database is undefined");
	var uri    = this.base_url + "/" + this._database;
	
	if(typeof id == "object")
	{
		callback = document;
		params   = {"method": "POST",
		            "uri"   : uri,
		            "json"  : id}
	}
	else
	{
		params   = {"method": "PUT",
		            "uri"   : uri + "/" + id,
		            "json"  : document}
	}
	
	this.request(params, callback);
}

CouchDB.prototype.request = function(params, callback)
{
	request(params, function(error, response, body)
	{
		if(callback)
		{
			callback(JSON.parse(body))
		}
	});
}



CouchDB.prototype.__defineGetter__("base_url", function()
{ 
	return this._scheme + this._host + ":" + this._port;
});