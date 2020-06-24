# Leader Board Load Test (LBLT)
This script generates semi-realistic leaderboard entries in MongoDB which can be used to test queries against.  Each documnet  is a unique combination of displayName, Level, and platform, which yields about 1,000,000 variant possibilities. It uses Upserts to either create a new doc, or to update an existing one if there. One of the less realistic optimisations i've made is that scores can be updated down as well as up, i.e. a random value is updated into the player's doc each time, we're not yet limiting the updates to only a higher score than current.

# Execution
The best way to run this script is via Docker, I have pre-built a docker container: https://hub.docker.com/r/jimthree/lb_up you can run it with sane defaults like this:

`docker run -e HOSTNAME="mongodb+srv://<user>:<pass>@<your connection>/lb?retryWrites=true&w=majority" -d jimthree/lb_up `

I tend to run about 10 containers in parallel, but you can scale this up or down as needed.

you can also use the environment variable MAXNUMFRIENDS to influence how many friends a player can randomly be given. Note, every update to a player will just assign a bunch of new random friends.  There is nothing smart or clever about this.  `-e MAXNUMFRIENDS=20` the default has been set at 10 (this is useful for reducing the size of the dataset)


# Output
The documents generated look like this:
```
{
	"_id" : ObjectId("5ef1bb02393076d766c55744"),
	"displayName" : "FakerMagnums",
	"level" : "Harmony",
	"platform" : "Xbox",
	"friends" : [
		"BoxerEroica",
		"DendiUltra",
		"FlashSummit",
		"RamboRaySterling",
		"f0restTettnang"
	],
	"last_updated" : ISODate("2020-06-23T08:19:14.628Z"),
	"score" : 794505,
	"update_count" : 1
}
```
Except that players have between 1 and 10 friends, the average is 5 (obviously)

# Indexes
The Script now also builds an index to support the upserts.
 
`db.lb.createIndex({ displayName: 1, platform: 1, level: 1 }) `


