require 'mongo'
require 'faker'
require 'slop'
require 'awesome_print'


opts = Slop.parse do |o|
    o.string '-h', '--host', 'the connection string for the MongoDB cluster (default: localhost)', default: "mongodb://localhost"
    o.string '-d', '--database', 'the database to use (default: leaderboard)', default: "leaderboard"
    o.string '-c', '--collection', 'the collection to use (default: lb)', default: "lb"
    o.integer '-m', '--maxscore','the highest possible score on the leaderboard (default: 1,000,000)', default: 1000000
    o.integer '-r', '--records','the number of records to generate (default: 10,000)', default: 10000
end

# set the logger level for the mongo driver
Mongo::Logger.logger.level = ::Logger::WARN

puts "Connecting to #{opts[:host]}, and db #{opts[:database]}"
DB = Mongo::Client.new(opts[:host])
DB.use(opts[:database])



def createRecord(maxscore,db,coll)
    record = 
    {
        "displayName" => "#{Faker::Esport.player}#{Faker::Beer.hop}",
        "score" => rand(maxscore),
        "level" => "#{Faker::Cosmere.metal} #{Faker::Cosmere.shard}", 
        "platform" => Faker::Game.platform,
        'ts' => Time.now()
    }
    puts record
    coll = db[coll]
    result = coll.insert_one(record)
end


 # Update a batch of documents
 for i in 0..opts[:records].to_i
    createRecord(opts[:maxscore],DB,opts[:collection])
    puts i
 end



