# frozen_string_literal: true

require 'mongo'
require 'faker'
require 'slop'
require 'awesome_print'

opts = Slop.parse do |o|
  o.string '-h', '--host', 'the connection string for the MongoDB cluster (default: localhost)', default: 'mongodb://localhost'
  o.string '-d', '--database', 'the database to use (default: leaderboard)', default: 'leaderboard'
  o.string '-c', '--collection', 'the collection to use (default: lb)', default: 'lb'
  o.integer '-m', '--maxscore', 'the highest possible score on the leaderboard (default: 1,000,000)', default: 1_000_000
  o.integer '-r', '--records', 'the number of records to generate (default: 10,000)', default: 10_000
end

batchSize = 1000

# set the logger level for the mongo driver
Mongo::Logger.logger.level = ::Logger::WARN

puts "Connecting to #{opts[:host]}, and db #{opts[:database]}"
DB = Mongo::Client.new(opts[:host])
DB.use(opts[:database])

def createRecords(_maxscore, db, coll, batchSize)
  @docs = []
  (1..batchSize).each do |_i|
    doc = makeDoc(_maxscore)
    @docs << doc
  end
  puts "."
  coll = db[coll]
  result = coll.insert_many(@docs)
end

def makeDoc(_maxscore)
  doc =
    {
      'displayName' => "#{Faker::Esport.player}#{Faker::Beer.hop}",
      'score' => rand(_maxscore),
      'level' => "#{Faker::Cosmere.shard}",
      'platform' => Faker::Game.platform,
      'ts' => Time.now
    }
end

batches = opts[:records]/batchSize
remainder = opts[:records]%batchSize

puts "going to make #{batches} batches of #{batchSize} docs with a remainder of #{remainder}"

(1..batches.to_i).each do |i|
  createRecords(opts[:maxscore], DB, opts[:collection],batchSize)
  puts i
end

createRecords(opts[:maxscore], DB, opts[:collection],remainder)