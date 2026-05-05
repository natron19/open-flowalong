class CreateWorkshopBriefs < ActiveRecord::Migration[8.1]
  def change
    create_table :workshop_briefs, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string  :topic,            null: false
      t.string  :audience,         null: false
      t.integer :duration_minutes, null: false
      t.text    :desired_outcome,  null: false
      t.text    :notes
      t.timestamps null: false
    end
  end
end
