class CreateWorkshopAgendas < ActiveRecord::Migration[8.1]
  def change
    create_table :workshop_agendas, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :workshop_brief, null: false, foreign_key: true, type: :uuid, index: { unique: true }
      t.references :user,           null: false, foreign_key: true, type: :uuid
      t.string :title,     null: false
      t.text   :body,      null: false
      t.text   :gemini_raw
      t.timestamps null: false
    end
  end
end
