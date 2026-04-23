class CreateVideos < ActiveRecord::Migration[8.0]
  def change
    create_table :videos do |t|
      t.references :user, null: false, foreign_key: true
      t.string :youtube_url
      t.string :youtube_id
      t.string :title
      t.text :description

      t.timestamps
    end
  end
end
