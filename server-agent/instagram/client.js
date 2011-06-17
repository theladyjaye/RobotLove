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

var endpoints = require("./endpoints");
var request   = require("request");
function Client(api_key)
{
	this.api_key = api_key;
}

Client.prototype.recentMediaForTag = function(tag, params, callback)
{
	/*
	
	PARAMETERS
	max_id	Return media after this max_id
	min_id	Return media before this min_id
	*/
	
	if(typeof this._recentMediaForTagUrl == "undefined")
	{
		this._recentMediaForTagUrl = this._formatUrl(endpoints.recentMediaForTag, {"api_key":this.api_key});
	}
	
	var uri = this._formatUrl(this._recentMediaForTagUrl, {"tag":tag});
	
	var params = {"method": "GET",
	              "uri"   : uri}
	
	request(params, this._instagramResponse(callback));
}

Client.prototype.recentMediaForLocation = function(location_id, params, callback)
{
	/*
	PARAMETERS
	max_id	Return media after this max_id
	min_id	Return media before this min_id
	min_timestamp	Return media after this UNIX timestamp
	max_timestamp	Return media before this UNIX timestamp
	*/
	
	if(typeof this._recentMediaForLocationUrl == "undefined")
	{
		this._recentMediaForLocationUrl = this._formatUrl(endpoints.recentMediaForLocation, {"api_key":this.api_key});
	}
	
	var uri = this._formatUrl(this._recentMediaForLocationUrl, {"location_id":location_id});
	
	var params = {"method": "GET",
	              "uri"   : uri}
	
	request(params, this._instagramResponse(callback));
}

Client.prototype._instagramResponse = function(callback)
{
	return function(error, response, body)
	{
		if (!error && response.statusCode == 200) 
		{
			var data = JSON.parse(body);
			var ok   = false;
			
			if(data.meta.code == 200)
			{
				ok = true;
			}
			
			callback(ok, data);
		}
	}
}

Client.prototype._formatUrl = function (url, params)
{
	var result = url;
	for(var key in params)
	{
		result = result.replace("@"+key, params[key]);
	}
	
	return result;
}

module.exports = Client;