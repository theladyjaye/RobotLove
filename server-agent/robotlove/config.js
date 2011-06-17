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

module.exports = {
	"interval" : 60000,
	"dropbox"  : "./dropbox",
	"couchdb"  : "robotlove",
	"instagram": {
		"api_key"           : "<your api key>",
		"location_id"       : "<location id>",
		"tag"               : "<# hashtag, you don't need the #>",
		"location_id_cache" : "__instagram_location",
		"tag_id_cache"      : "__instagram_tag",
	}
	
}