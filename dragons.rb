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

def find_strength(hash)
  hash.key(hash.values.max)
end

def build_dragon(knight, weather, logger)

  if weather['report']['code'] == 'SRO'
    logger.info("Storm, no dragon sent.")
    return dragon = nil

  elsif weather['report']['code'] == 'FUNDEFINEDG'
    scaleThickness  = 5
    clawSharpness   = 10
    wingStrength    = 5
    fireBreath      = 0
  elsif weather['report']['code'] == 'T E'
    scaleThickness  = 5
    clawSharpness   = 5
    wingStrength    = 5
    fireBreath      = 5
  else
    knight.delete("name")
    scaleThickness  = knight['attack']
    clawSharpness   = knight['armor']
    wingStrength    = knight['agility']
    fireBreath      = knight['endurance']
    # Add 2 points to dragon attribute matching knights strength
    case find_strength(knight)
    when 'attack'
      scaleThickness += 2
    when 'armor'
      clawSharpness += 2
    when 'agility'
      wingStrength += 2
    when 'endurance'
      fireBreath += 2
    end

  # Remove knights strength to find knight's second highest attribute, subtract 2
  # from matching dragon attribute.
    knight.delete(find_strength(knight))

    case find_strength(knight)
    when 'attack'
      scaleThickness -= 2
    when 'armor'
      clawSharpness -= 2
    when 'agility'
      wingStrength -= 2
    when 'endurance'
      fireBreath -= 2
    end

  end

  return dragon = {"scaleThickness" => scaleThickness, "clawSharpness" => clawSharpness, "wingStrength" => wingStrength, "fireBreath" => fireBreath}
end

def run_game(url, logger)
  game = party_get(url, 'api/game')
  gameId = game['gameId']
  knight = game['knight']
  weather = party_get(url, "weather/api/report/#{gameId}")

  logger.debug(knight)
  logger.info("Running game: #{gameId}")
  logger.info("Weather Code: #{weather['report']['code']}")
  logger.debug("Weather Message: #{weather['report']['message']}")

  s = build_dragon(knight, weather, logger)


  solution = {'dragon'=> s }
  logger.debug(solution)

  result = party_put(url,"api/game/#{gameId}/solution", solution)

  logger.info(result["status"])

end

logger = Logger.new("./logs/#{Time.now.strftime('%F_%H%M%S')}_Battle.log")

10.times do
  run_game(url, logger)
end
