class CreateRepetitionSchemes < ActiveRecord::Migration
  def change
    create_table :repetition_schemes do |t|

      t.integer :weekdays
      t.integer :month_day
      t.integer :year_day

      t.timestamps null: false
    end
  end
end
