require 'cute_pets'
require 'minitest/autorun'

# Couldn't find a way to effectively mock modules via minitest :(
describe 'CutePets' do
  describe '.post_pet' do
    before do
      @pet_hash = { name:        'schooples',
                   link:         'http://www.example.com/schooples',
                   pic:          'http://www.example.com/schooples.jpg',
                   description:  'neutured female fluffy dog'
                 }
    end
    it 'fetches pet finder data when the env var datasource is set to petfinder' do
      ENV.stub :fetch, 'petfinder' do
        PetFetcher.stub(:get_petfinder_pet, @pet_hash) do
          TweetGenerator.stub(:tweet, nil, [String, String]) do
            CutePets.post_pet
          end
        end
      end
    end

    it 'fetches 24petconnect data when the env var datasource is set to 24petconnect' do
      ENV.stub :fetch, '24petconnect' do
        PetFetcher.stub(:get_24petconnect_pet, @pet_hash) do
          TweetGenerator.stub(:tweet, nil, [String, String]) do
            CutePets.post_pet
          end
        end
      end
    end
  end
end