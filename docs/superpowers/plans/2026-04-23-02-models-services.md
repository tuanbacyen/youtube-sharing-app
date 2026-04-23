# Plan 2: Models & Services

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create all database migrations, models (User, Video, JwtDenylist) and services (JwtService, YoutubeOembedService) with full RSpec coverage.

**Architecture:** Standard ActiveRecord models. JwtService encodes/decodes JWT with `jti` + `exp`. YoutubeOembedService fetches video title from YouTube's free oEmbed API and extracts the YouTube video ID from a URL. All external HTTP calls are stubbed in specs via WebMock.

**Tech Stack:** Rails 8, ActiveRecord, bcrypt (has_secure_password), jwt gem, Net::HTTP (stdlib)

**Previous plan:** [01 — Backend Setup](2026-04-23-01-backend-setup.md)
**Next plan:** [03 — Grape API](2026-04-23-03-grape-api.md)

---

## Task 1: Database migrations

**Files:**
- Create: `db/migrate/xxx_create_users.rb`
- Create: `db/migrate/xxx_create_videos.rb`
- Create: `db/migrate/xxx_create_jwt_denylists.rb`

- [ ] **Step 1: Generate migrations**

```bash
bundle exec rails generate migration CreateUsers email:string password_digest:string
bundle exec rails generate migration CreateVideos user:references youtube_url:string youtube_id:string title:string description:text
bundle exec rails generate migration CreateJwtDenylists jti:string exp:datetime
```

- [ ] **Step 2: Edit users migration to add NOT NULL + unique index**

`db/migrate/xxx_create_users.rb`:
```ruby
class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.timestamps
    end
    add_index :users, :email, unique: true
  end
end
```

- [ ] **Step 3: Edit videos migration to add NOT NULL**

`db/migrate/xxx_create_videos.rb`:
```ruby
class CreateVideos < ActiveRecord::Migration[8.0]
  def change
    create_table :videos do |t|
      t.references :user, null: false, foreign_key: true
      t.string :youtube_url, null: false
      t.string :youtube_id
      t.string :title
      t.text :description
      t.timestamps
    end
  end
end
```

- [ ] **Step 4: Edit jwt_denylists migration to add NOT NULL + unique index**

`db/migrate/xxx_create_jwt_denylists.rb`:
```ruby
class CreateJwtDenylists < ActiveRecord::Migration[8.0]
  def change
    create_table :jwt_denylists do |t|
      t.string :jti, null: false
      t.datetime :exp, null: false
      t.timestamps
    end
    add_index :jwt_denylists, :jti, unique: true
  end
end
```

- [ ] **Step 5: Run migrations**

```bash
bundle exec rails db:migrate
```

Expected: All 3 tables created in both development and test databases

- [ ] **Step 6: Commit**

```bash
git add . && git commit -m "feat: add database migrations for users, videos, jwt_denylists"
```

---

## Task 2: User model + JwtDenylist model + specs

**Files:**
- Create: `app/models/user.rb`
- Create: `app/models/jwt_denylist.rb`
- Create: `spec/factories/users.rb`
- Create: `spec/models/user_spec.rb`

- [ ] **Step 1: Write failing user model spec**

`spec/models/user_spec.rb`:
```ruby
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should have_secure_password }
  end

  describe 'associations' do
    it { should have_many(:videos).dependent(:destroy) }
  end

  describe 'email normalization' do
    it 'downcases email before save' do
      user = create(:user, email: 'TEST@EXAMPLE.COM')
      expect(user.reload.email).to eq('test@example.com')
    end
  end
end
```

- [ ] **Step 2: Create user factory**

`spec/factories/users.rb`:
```ruby
FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { 'password123' }
  end
end
```

- [ ] **Step 3: Run spec to confirm failure**

```bash
bundle exec rspec spec/models/user_spec.rb
```

Expected: FAILED — `User` class not defined

- [ ] **Step 4: Implement User model**

`app/models/user.rb`:
```ruby
class User < ApplicationRecord
  has_secure_password
  has_many :videos, dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 6 }, on: :create

  before_save { self.email = email.downcase }
end
```

- [ ] **Step 5: Implement JwtDenylist model**

`app/models/jwt_denylist.rb`:
```ruby
class JwtDenylist < ApplicationRecord
  validates :jti, presence: true, uniqueness: true
  validates :exp, presence: true
end
```

- [ ] **Step 6: Run spec to confirm pass**

```bash
bundle exec rspec spec/models/user_spec.rb
```

Expected: All examples pass

- [ ] **Step 7: Commit**

```bash
git add . && git commit -m "feat: add User and JwtDenylist models with validations"
```

---

## Task 3: JwtService + spec

**Files:**
- Create: `app/services/jwt_service.rb`
- Create: `spec/services/jwt_service_spec.rb`

- [ ] **Step 1: Write failing spec**

`spec/services/jwt_service_spec.rb`:
```ruby
require 'rails_helper'

RSpec.describe JwtService do
  let(:payload) { { user_id: 1 } }

  describe '.encode' do
    it 'returns a JWT string' do
      expect(JwtService.encode(payload)).to be_a(String)
    end

    it 'embeds jti and exp into the token' do
      token = JwtService.encode(payload)
      decoded = JwtService.decode(token)
      expect(decoded['jti']).to be_present
      expect(decoded['exp']).to be_present
    end
  end

  describe '.decode' do
    it 'returns the payload for a valid token' do
      token = JwtService.encode(payload)
      expect(JwtService.decode(token)['user_id']).to eq(1)
    end

    it 'returns nil for an invalid token' do
      expect(JwtService.decode('invalid.token.here')).to be_nil
    end

    it 'returns nil for an expired token' do
      token = JwtService.encode(payload.merge(exp: 1.hour.ago.to_i))
      expect(JwtService.decode(token)).to be_nil
    end
  end
end
```

- [ ] **Step 2: Run spec to confirm failure**

```bash
bundle exec rspec spec/services/jwt_service_spec.rb
```

Expected: FAILED — `uninitialized constant JwtService`

- [ ] **Step 3: Implement JwtService**

`app/services/jwt_service.rb`:
```ruby
class JwtService
  ALGORITHM = 'HS256'

  def self.encode(payload)
    payload = payload.merge(
      jti: SecureRandom.uuid,
      exp: 24.hours.from_now.to_i
    )
    JWT.encode(payload, secret, ALGORITHM)
  end

  def self.decode(token)
    decoded = JWT.decode(token, secret, true, algorithm: ALGORITHM)
    HashWithIndifferentAccess.new(decoded.first)
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end

  def self.secret
    ENV.fetch('JWT_SECRET', Rails.application.credentials.secret_key_base)
  end
end
```

- [ ] **Step 4: Run spec to confirm pass**

```bash
bundle exec rspec spec/services/jwt_service_spec.rb
```

Expected: All examples pass

- [ ] **Step 5: Commit**

```bash
git add . && git commit -m "feat: add JwtService for encoding and decoding JWT tokens"
```

---

## Task 4: Video model + YoutubeOembedService + specs

**Files:**
- Create: `app/models/video.rb`
- Create: `app/services/youtube_oembed_service.rb`
- Create: `spec/factories/videos.rb`
- Create: `spec/models/video_spec.rb`
- Create: `spec/services/youtube_oembed_service_spec.rb`

- [ ] **Step 1: Write failing video model spec**

`spec/models/video_spec.rb`:
```ruby
require 'rails_helper'

RSpec.describe Video, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:youtube_url) }

    it 'rejects non-YouTube URLs' do
      video = build(:video, youtube_url: 'https://vimeo.com/123')
      expect(video).not_to be_valid
      expect(video.errors[:youtube_url]).to include('is not a valid YouTube URL')
    end

    it 'accepts standard youtube.com URLs' do
      video = build(:video, youtube_url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ')
      expect(video).to be_valid
    end

    it 'accepts youtu.be short URLs' do
      video = build(:video, youtube_url: 'https://youtu.be/dQw4w9WgXcQ')
      expect(video).to be_valid
    end
  end
end
```

- [ ] **Step 2: Write failing YoutubeOembedService spec**

`spec/services/youtube_oembed_service_spec.rb`:
```ruby
require 'rails_helper'

RSpec.describe YoutubeOembedService do
  describe '.extract_id' do
    it 'extracts id from standard URL' do
      expect(YoutubeOembedService.extract_id('https://www.youtube.com/watch?v=dQw4w9WgXcQ')).to eq('dQw4w9WgXcQ')
    end

    it 'extracts id from short URL' do
      expect(YoutubeOembedService.extract_id('https://youtu.be/dQw4w9WgXcQ')).to eq('dQw4w9WgXcQ')
    end

    it 'returns nil for non-YouTube URL' do
      expect(YoutubeOembedService.extract_id('https://vimeo.com/123')).to be_nil
    end
  end

  describe '.fetch' do
    let(:url) { 'https://www.youtube.com/watch?v=dQw4w9WgXcQ' }

    context 'when oEmbed responds with success' do
      before do
        stub_request(:get, /youtube\.com\/oembed/)
          .to_return(
            status: 200,
            body: { title: 'Rick Astley - Never Gonna Give You Up', author_name: 'Rick Astley' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns title and description' do
        result = YoutubeOembedService.fetch(url)
        expect(result[:title]).to eq('Rick Astley - Never Gonna Give You Up')
        expect(result[:description]).to eq('Rick Astley')
      end
    end

    context 'when oEmbed responds with error' do
      before do
        stub_request(:get, /youtube\.com\/oembed/).to_return(status: 404)
      end

      it 'returns nil' do
        expect(YoutubeOembedService.fetch(url)).to be_nil
      end
    end
  end
end
```

- [ ] **Step 3: Create video factory**

`spec/factories/videos.rb`:
```ruby
FactoryBot.define do
  factory :video do
    user
    youtube_url { 'https://www.youtube.com/watch?v=dQw4w9WgXcQ' }
    youtube_id { 'dQw4w9WgXcQ' }
    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
  end
end
```

- [ ] **Step 4: Run specs to confirm failure**

```bash
bundle exec rspec spec/models/video_spec.rb spec/services/youtube_oembed_service_spec.rb
```

Expected: FAILED

- [ ] **Step 5: Implement YoutubeOembedService**

`app/services/youtube_oembed_service.rb`:
```ruby
require 'net/http'
require 'json'
require 'cgi'

class YoutubeOembedService
  OEMBED_URL = 'https://www.youtube.com/oembed'
  YOUTUBE_REGEX = /(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})/

  def self.extract_id(url)
    url.to_s.match(YOUTUBE_REGEX)&.captures&.first
  end

  def self.fetch(youtube_url)
    uri = URI("#{OEMBED_URL}?url=#{CGI.escape(youtube_url)}&format=json")
    response = Net::HTTP.get_response(uri)
    return nil unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    { title: data['title'], description: data['author_name'] }
  rescue StandardError
    nil
  end
end
```

- [ ] **Step 6: Implement Video model**

`app/models/video.rb`:
```ruby
class Video < ApplicationRecord
  belongs_to :user

  validates :youtube_url, presence: true
  validate :youtube_url_format

  before_create :set_youtube_id

  private

  def youtube_url_format
    return if YoutubeOembedService.extract_id(youtube_url.to_s)
    errors.add(:youtube_url, 'is not a valid YouTube URL')
  end

  def set_youtube_id
    self.youtube_id = YoutubeOembedService.extract_id(youtube_url)
  end
end
```

- [ ] **Step 7: Run specs to confirm pass**

```bash
bundle exec rspec spec/models/video_spec.rb spec/services/youtube_oembed_service_spec.rb
```

Expected: All examples pass

- [ ] **Step 8: Run full suite — no regressions**

```bash
bundle exec rspec
```

Expected: All examples pass

- [ ] **Step 9: Commit**

```bash
git add . && git commit -m "feat: add Video model and YoutubeOembedService with URL validation"
```
