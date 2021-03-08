# frozen_string_literal: true

require 'mongo'
require 'faker'
require 'slop'
require 'awesome_print'
require 'progress_bar'

opts = Slop.parse do |o|
  o.string '-h', '--host', 'the connection string for the MongoDB cluster (default: localhost)', default: 'mongodb://localhost'
  o.string '-d', '--database', 'the database to use (default: leaderboard)', default: 'leaderboard'
  o.string '-c', '--collection', 'the collection to use (default: lb)', default: 'rank'
  o.integer '-m', '--maxscore', 'the highest possible score on the leaderboard (default: 1,000,000)', default: 1_000_000
  o.integer '-r', '--records', 'the number of records to generate (default: 10,000)', default: 10_000
  o.integer '-b', '--batch', 'the batch size for bulk insertion (default: 1,000)', default: 1_000
end

# set the logger level for the mongo driver
Mongo::Logger.logger.level = ::Logger::WARN

puts "Connecting to #{opts[:host]}, and db #{opts[:database]}"
# added the database to connection string
DB = Mongo::Client.new(opts[:host], database: opts[:database])


def createRecords(max_score, db, coll, batchSize)
  @docs = []
  (1..batchSize).each do |_i|
    doc = makeDoc(max_score)
    @docs << doc
  end
  result = db[coll].insert_many(@docs)
end

def makeDoc(max_score)
  doc =
    {
      'displayName' => "#{[:"", :"Sir", :"King", :"Lord", :"Lady", :"Cuz", :"Mizz" , :"Epic" , :"Fast" , :"Smart", :"" , :""].sample}#{Faker::Esport.player}#{Faker::Beer.hop}#{[:"", :s, :er, :ing, :ible, :xx, :xxx ].sample}",
      'score' => rand(max_score),
      'ts' => Time.now
    }
end

batches = opts[:records] / opts[:batch]
remainder = opts[:records] % opts[:batch]

bar = ProgressBar.new(batches)

puts "going to make #{batches} batches of #{opts[:batch]} docs with a remainder of #{remainder}"

(1..batches.to_i).each do |i|
  createRecords(opts[:maxscore], DB, opts[:collection], opts[:batch])
  bar.increment!
end

createRecords(opts[:maxscore], DB, opts[:collection], remainder)
