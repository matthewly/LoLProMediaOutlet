class CreatePlayers < ActiveRecord::Migration
  def change
    create_table :players do |t|
      t.string :name
      t.string :facebook_prof
      t.string :twitter_prof
      t.string :twitch_prof

      t.timestamps null: false
    end
  end
end
