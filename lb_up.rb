# frozen_string_literal: true

require 'mongo'
require 'faker'
require 'slop'

opts = Slop.parse do |o|
  o.string '-h', '--host', 'the connection string for the MongoDB cluster (default: localhost)', default: 'mongodb://localhost'
  o.string '-d', '--database', 'the database to use (default: leaderboard)', default: 'leaderboard'
  o.string '-c', '--collection', 'the collection to use (default: lb)', default: 'lb'
  o.integer '-m', '--maxscore', 'the highest possible score on the leaderboard (default: 1,000,000)', default: 1_000_000
  o.integer '-f', '--maxfriends', 'The maximum amount of friends a player can have', default: 10
  o.integer '-q', '--debugfreq', 'the number of updates to complete before reporting debug', default: 1000
  o.integer '-r', '--refreshfriends', 'the number of updates to complete before refreshing friendlistpool', default: 10000
  o.integer '-p', '--friendpoolsamplesize', 'the number of friends in the pool', default: 1000

end
# globalVar for the friend pool
$friendPool = []

# set the logger level for the mongo driver
Mongo::Logger.logger.level = ::Logger::WARN

puts "Connecting to #{opts[:host]}, and db #{opts[:database]}"
DB = Mongo::Client.new(opts[:host])
DB.use(opts[:database])

DB[opts[:collection]].indexes.create_one(
  { displayName: 1, platform: 1, level: 1 },
  name: 'ix_dpl'
)

def refreshFriendsPool(db, coll, samplesize)
  #freindAgg = db[coll].aggregate([{ '$sample' => { 'size' => rand(max_friends) + 1 } }, { '$project' => { '_id' => 0, 'displayName' => 1 } }])
  freindAgg = db[coll].aggregate([{ '$sample' => { 'size' => samplesize + 1 } }, { '$project' => { '_id' => 0, 'displayName' => 1 } }])
  freindAgg.each do |doc|
    $friendPool << doc[:displayName]
  end
end


def makeDoc(db, coll, max_score, max_friends)
  result = db[coll].update_one({  'displayName' => "#{Faker::Esport.player}#{Faker::Beer.hop}#{[:"", :s, :er].sample}",
                                  'level' => Faker::Cosmere.shard.to_s,
                                  'platform' => Faker::Game.platform },
                               {
                                 '$set' => { 'score' => rand(max_score), 'last_updated' => Time.now, 'friends' => $friendPool.sample(rand(max_friends)) },
                                 '$inc' => { 'update_count': 1 }
                               },
                               upsert: true)
end

puts 'Connected....'

i = 0
t = Time.now
loop do
  makeDoc(DB, opts[:collection], opts[:maxscore], opts[:maxfriends])
  i += 1
  if i % opts[:debugfreq] == 0
    puts "Performed another #{opts[:debugfreq]} updates in #{Time.now - t} for a total of #{i}"
    t = Time.now
  end
  if i % opts[:refreshfriends] == 0
    r = Time.now
    puts "refreshing friends list pool..."
    refreshFriendsPool(DB, opts[:collection],opts[:friendpoolsamplesize])
    puts "...Done in #{Time.now-r}s."
  end
end
