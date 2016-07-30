require 'httparty'
require 'json'
require 'logger'

url = 'http://www.dragonsofmugloar.com/'

def party_get(base_url, path)
  resource = base_url + path
  r = HTTParty.get(resource)
end

def party_put(base_url, path, options)
  resource = base_url + path
  headers = {'Content-Type' => 'application/json'}
  r = HTTParty.put(resource, :body => options.to_json, :headers => headers)

  JSON.parse(r.body)
end

def normal_fight(hash)

  hash.each do |attribute, value|
    # remove from hash if not a valid numeric attribute (e.g. - knight name)
    if value.class != Fixnum
      hash.delete(attribute)
    end
  end

  # In normal weather, add 2 to knights strongest attribute, remove 1 from knights
  # 2nd and 3rd highest attributes.
  att_array = hash.sort_by {|attribute, value| value}
  att_array[-1][-1] += 2
  att_array[2][1] -= 1
  att_array[1][1] -= 1

  return att_array.to_h
end

def build_dragon(knight, weather, logger)

  # Send no dragon in storms
  if weather['report']['code'] == 'SRO'
    logger.info("Storm, no dragon sent.")
    return dragon = nil

  # Max clawSharpness if heavy rain with floods
  elsif weather['report']['code'] == 'HVA'
    scaleThickness  = 5
    clawSharpness   = 10
    wingStrength    = 5
    fireBreath      = 0

  # Balanced dragon if The Long Dry
  elsif weather['report']['code'] == 'T E'
    scaleThickness  = 5
    clawSharpness   = 5
    wingStrength    = 5
    fireBreath      = 5

  # Normal fight
  else
    h = normal_fight(knight) # get modified attributes for a normal fight
    scaleThickness  = h['attack']
    clawSharpness   = h['armor']
    wingStrength    = h['agility']
    fireBreath      = h['endurance']
  end

  return dragon = { "scaleThickness" => scaleThickness,
                    "clawSharpness" => clawSharpness,
                    "wingStrength" => wingStrength,
                    "fireBreath" => fireBreath }
end

def run_game(url, logger)
  game = party_get(url, 'api/game')
  gameId = game['gameId']
  knight = game['knight']
  weather = party_get(url, "weather/api/report/#{gameId}")

  logger.debug("Running game: #{gameId}")
  logger.debug("Weather Code: #{weather['report']['code']}")
  logger.debug(knight)

  dragon = build_dragon(knight, weather, logger)
  solution = {'dragon'=> dragon }
  logger.debug(solution)

  result = party_put(url,"api/game/#{gameId}/solution", solution)
  logger.info(result["status"])
  result["status"]
end

logger = Logger.new("./logs/#{Time.now.strftime('%F_%H%M%S')}_Battle.log")

n = 10 # Number of games to run
v = 0 # Initialize number of Victories
d = 0 # Initialize number of Defeats

n.times do
  r = run_game(url, logger)
  if r == 'Victory'
    v += 1
  elsif r == 'Defeat'
    d += 1
  end
end


puts "Game run #{n} times."
puts "#{v} victories"
puts "#{d} defeat(s)"
puts "Success rate: #{((v.to_f/n) * 100).round(2)}%"
