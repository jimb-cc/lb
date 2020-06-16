# frozen_string_literal: true

require 'mongo'
require 'faker'
require 'slop'
require 'awesome_print'
require 'progress_bar'

opts = Slop.parse do |o|
  o.string '-h', '--host', 'the connection string for the MongoDB cluster (default: localhost)', default: 'mongodb://localhost'
  o.string '-d', '--database', 'the database to use (default: leaderboard)', default: 'leaderboard'
  o.string '-c', '--collection', 'the collection to use (default: lb)', default: 'lb'
  o.integer '-m', '--maxscore', 'the highest possible score on the leaderboard (default: 1,000,000)', default: 1_000_000
  o.integer '-r', '--records', 'the number of records to generate (default: 10,000)', default: 10_000
  o.integer '-f', '--maxFriends', 'The maximum amount of friends a player can have', default: 50
end

batchSize = 1000
max_friends = 20
# set the logger level for the mongo driver
Mongo::Logger.logger.level = ::Logger::WARN

puts "Connecting to #{opts[:host]}, and db #{opts[:database]}"
DB = Mongo::Client.new(opts[:host])
DB.use(opts[:database])

def createRecords(max_score, db, coll, batchSize, max_friends)
  @docs = []
  (1..batchSize).each do |_i|
    doc = makeDoc(max_score, max_friends)
    @docs << doc
  end
  
  #coll = db[coll]
  result = db[coll].insert_many(@docs)
end

def makeDoc(max_score, max_friends)
  doc =
    {
      'displayName' => "#{Faker::Esport.player}#{Faker::Beer.hop}",
      'score' => rand(max_score),
      'level' => Faker::Cosmere.shard.to_s,
      'platform' => Faker::Game.platform,
      'ts' => Time.now
    }
    friends = []
    (1..(rand(max_friends)+1)).each do
      friends << "#{Faker::Esport.player}#{Faker::Beer.hop}"
    end
    doc["friends"] = friends
    doc
end

batches = opts[:records] / batchSize
remainder = opts[:records] % batchSize

bar = ProgressBar.new(batches)


puts "going to make #{batches} batches of #{batchSize} docs with a remainder of #{remainder}"

(1..batches.to_i).each do |i|
  createRecords(opts[:maxscore], DB, opts[:collection], batchSize, max_friends)
  bar.increment!
end

createRecords(opts[:maxscore], DB, opts[:collection], remainder, opts[:maxFriends])
