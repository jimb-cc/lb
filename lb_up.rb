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
  o.integer '-f', '--maxfriends', 'The maximum amount of friends a player can have', default: 50
end

max_friends = 20
# set the logger level for the mongo driver
Mongo::Logger.logger.level = ::Logger::WARN

puts "Connecting to #{opts[:host]}, and db #{opts[:database]}"
DB = Mongo::Client.new(opts[:host])
DB.use(opts[:database])

bar = ProgressBar.new(opts[:records])

def makeDoc(db, coll,num_docs, max_score, max_friends, bar)
  (1..num_docs.to_i).each do |_i|
    friends = []
    (1..(rand(max_friends) + 1)).each do
      friends << "#{Faker::Esport.player}#{Faker::Beer.hop}"
    end

    result = db[coll].update_one({  'displayName' => "#{Faker::Esport.player}#{Faker::Beer.hop}",
                                    'level' => Faker::Cosmere.shard.to_s,
                                    'platform' => Faker::Game.platform },
                                 { 
                                   '$set' => {'score' => rand(max_score),'last_updated' => Time.now,'friends' => friends}, 
                                   '$inc' => { 'update_count': 1 } 
                                },
                                 upsert: true)
      bar.increment!
  end
end

makeDoc(DB, opts[:collection],opts[:records], opts[:maxscore], opts[:maxfriends], bar)
