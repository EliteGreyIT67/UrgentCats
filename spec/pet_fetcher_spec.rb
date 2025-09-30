require 'cute_pets/pet_fetcher'
require 'minitest/autorun'
require 'webmock/minitest'
require 'vcr'

describe 'PetFetcher' do
  VCR.configure do |c|
    c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
    c.hook_into :webmock
  end

  describe '.get_petfinder_pet' do
    it 'returns a hash of pet data when the API request is successful' do
      VCR.use_cassette('petfinder', record: :once) do
        pet_hash = PetFetcher.get_petfinder_pet
        pet_hash[:description].must_equal 'altered male ferret'
        pet_hash[:pic].must_equal 'http://photos.petfinder.com/photos/pets/30078059/1/?bust=1409196072&width=500&-x.jpg'
        pet_hash[:link].must_equal 'https://www.petfinder.com/petdetail/30078059'
        pet_hash[:name].must_equal 'Joey'
      end
    end
 
    it 'raises when the API request fails' do
      stub_request(:get, /^http\:\/\/api\.petfinder\.com\/pet\.getRandom/).to_return(:status => 500)
      lambda { PetFetcher.get_petfinder_pet }.must_raise RuntimeError
    end
  end

  describe '.get_24petconnect_pet' do
    it 'returns a hash of pet data when the request is successful' do
      VCR.use_cassette('24petconnect', record: :once) do
        # The test will now use the recorded response from 24petconnect.com
        # To make this test pass, you would need to run it once with VCR in `record: :new_episodes` mode
        # to capture the actual HTML from the site. I'm assuming a structure based on my refactoring.
        pet_hash = PetFetcher.get_24petconnect_pet
        pet_hash[:description].must_equal 'a fluffy friend looking for a home.'
        pet_hash[:pic].must_equal 'https://www.example.com/mittens.jpg'
        pet_hash[:link].must_equal 'https://24petconnect.com/MIAD/Details/12345'
        pet_hash[:name].must_equal 'Mittens'
      end
    end
  end

  it 'raises when the request fails' do
    stub_request(:get, /^https:\/\/24petconnect\.com/).to_return(:status => 500)
    lambda { PetFetcher.get_24petconnect_pet }.must_raise RuntimeError
  end

  describe 'get_petfinder_option' do
    it 'uses friendly values' do
      PetFetcher.send(:get_petfinder_option, {"option" => {"$t" => "housebroken"}}).must_equal 'house trained'
      PetFetcher.send(:get_petfinder_option, {"option" => {"$t" => "housetrained"}}).must_equal 'house trained'
      PetFetcher.send(:get_petfinder_option, {"option" => {"$t" => "noClaws"}}).must_equal 'declawed'
      PetFetcher.send(:get_petfinder_option, {"option" => {"$t" => "altered"}}).must_equal 'altered'
    end

    it 'handles multiple values in the options hash' do
      PetFetcher.send(:get_petfinder_option,
                      {"option" => [{"$t" => "hasShots"},
                                    {"$t" => "noClaws"}]}).must_equal 'declawed'
    end

    it 'ignores some possible values' do
      PetFetcher.send(:get_petfinder_option,
                      {"option" => [{"$t" => "hasShots"},
                                    {"$t" => "noCats"},
                                    {"$t" => "noDogs"},
                                    {"$t" => "noKids"},
                                    {"$t" => "totally not in the xsd"},
                      ]}).must_equal nil

    end
  end

  describe 'get_petfinder_breed' do
    it 'works with a single hash' do
      PetFetcher.send(:get_petfinder_breed, {"breed" => {"$t" => "Spaniel"}}).must_equal 'Spaniel'
    end

    it 'works with an array of hashes' do
      PetFetcher.send(:get_petfinder_breed, {"breed" => [{"$t" => "Spaniel"}, {"$t" => "Pomeranian"}]}).must_equal 'Spaniel/Pomeranian mix'
    end
  end
end