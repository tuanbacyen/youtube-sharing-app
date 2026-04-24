class AddUniqueIndexToVideosYoutubeId < ActiveRecord::Migration[8.0]
  def change
    add_index :videos, :youtube_id, unique: true
  end
end
