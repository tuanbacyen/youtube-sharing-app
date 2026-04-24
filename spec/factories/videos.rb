FactoryBot.define do
  factory :video do
    sequence(:youtube_id) { |n| "dQw4w9WgXc#{n}" }
    youtube_url { "https://www.youtube.com/watch?v=#{youtube_id}" }
    user
    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
  end
end
