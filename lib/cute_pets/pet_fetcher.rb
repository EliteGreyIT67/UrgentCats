require 'net/http'
require 'json'
require 'open-uri'
require 'hpricot'
require 'dotenv'
Dotenv.load

module PetFetcher
  extend self

  def get_petfinder_pet()
    uri = URI('http://api.petfinder.com/pet.getRandom')
    params = {
      format:    'json',
      key:        ENV.fetch('petfinder_key'),
      shelterid:  get_petfinder_shelter_id,
      output:    'full'
    }
    uri.query = URI.encode_www_form(params)
    response = Net::HTTP.get_response(uri)

    if response.kind_of? Net::HTTPSuccess
      json = JSON.parse(response.body)
      status_message = json['petfinder']['header']['status']['message']['$t']
      if status_message == 'shelter opt-out'
        raise 'The chosen shelter opted out of being accesible via the API'
      elsif status_message == 'unauthorized key'
        raise 'Check that your Petfinder API key is configured correctly'
      elsif status_message
        raise status_message
      end
      pet_json  = json['petfinder']['pet']
      {
        pic:   get_photo(pet_json),
        link:  "https://www.petfinder.com/petdetail/#{pet_json['id']['$t']}",
        name:  pet_json['name']['$t'].capitalize,
        description: [get_petfinder_option(pet_json['options']), get_petfinder_sex(pet_json['sex']['$t']),  get_petfinder_breed(pet_json['breeds'])].compact.join(' ').downcase
      }
    else
      raise 'PetFinder api request failed'
    end
  end

  def get_24petconnect_pet()
    shelter_id = get_24petconnect_shelter_id
    uri = URI("https://24petconnect.com/#{shelter_id}/")
    response = Net::HTTP.get_response(uri)

    if response.kind_of? Net::HTTPSuccess
      doc = Hpricot(response.body)
      # Find all the pet containers; you might need to adjust the selector
      # based on the actual HTML of the site. I'm assuming a structure here.
      pets = doc.search('//div[@class="animal-card"]') # This selector is a guess
      random_pet_html = pets.sample

      if random_pet_html
        pet_name_element = random_pet_html.at('//h3[@class="animal-name"]') # guess
        pet_description_element = random_pet_html.at('//p[@class="animal-description"]') # guess
        pet_link_element = random_pet_html.at('//a[@class="animal-link"]') # guess
        pet_pic_element = random_pet_html.at('//img[@class="animal-image"]') # guess


        name = pet_name_element ? pet_name_element.inner_text.strip : "A cute pet"
        description = pet_description_element ? pet_description_element.inner_text.strip : "a very good pet."
        link = pet_link_element ? "https://24petconnect.com" + pet_link_element['href'] : "https://24petconnect.com/#{shelter_id}"
        pic = pet_pic_element ? pet_pic_element['src'] : "" # Provide a default image if none is found

        {
          pic:   pic,
          link:  link,
          name:  name.capitalize,
          description: description.downcase
        }
      else
        raise "Couldn't find any pets on the page."
      end
    else
      raise '24petconnect.com request failed'
    end
  end

private

  def get_petfinder_sex(sex_abbreviation)
    sex_abbreviation.downcase == 'f' ? 'female' : 'male'
  end

  PETFINDER_ADJECTIVES = {
    'housebroken' => 'house trained',
    'housetrained' => 'house trained',
    'noClaws'     => 'declawed',
    'altered'     => 'altered',
    'noDogs'      => nil,
    'noCats'      => nil,
    'noKids'      => nil,
    'hasShots'    => nil
  }.freeze

  def get_petfinder_option(option_hash)
    if option_hash['option']
      [option_hash['option']].flatten.map { |hsh| PETFINDER_ADJECTIVES[hsh['$t']] }.compact.first
    else
      option_hash['$t']
    end
  end

  def get_petfinder_breed(breeds)
    if breeds['breed'].is_a?(Array)
      "#{breeds['breed'].map(&:values).flatten.join('/')} mix"
    else
      breeds['breed']['$t']
    end
  end

  def self.get_photo(pet)
    if !pet['media']['photos']['photo'].nil?
      pet['media']['photos']['photo'][2]['$t']
    end
  end

  def get_petfinder_shelter_id
    get_shelter_id(ENV.fetch('petfinder_shelter_id'))
  end

  def get_24petconnect_shelter_id
    get_shelter_id(ENV.fetch('twenty_four_pet_connect_shelter_id'))
  end

  def get_shelter_id(id)
    id.split(',').sample
  end
end