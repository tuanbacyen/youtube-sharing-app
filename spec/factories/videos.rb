FactoryBot.define do
  factory :video do
    user
    youtube_url { 'https://www.youtube.com/watch?v=dQw4w9WgXcQ' }
    youtube_id { 'dQw4w9WgXcQ' }
    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
  end
end
