class AddUniqueIndexToVideosYoutubeId < ActiveRecord::Migration[8.0]
  def change
    # Remove duplicates keeping the most recent record before adding the unique index
    execute <<~SQL
      DELETE FROM videos
      WHERE id NOT IN (
        SELECT MAX(id) FROM videos GROUP BY youtube_id
      )
    SQL
    add_index :videos, :youtube_id, unique: true
  end
end
