FactoryBot.define do

  factory :affiliation, class: StashDatacite::Affiliation do
    long_name { Faker::Lorem.unique.word }
    ror_id { "https://ror.org/#{Faker::IDNumber.valid}" }
  end

end
