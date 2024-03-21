class CreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      t.string :phone_number, null: false
      t.string :email
      t.string :cognito_sub, null: false
      t.string :username, null: false

      t.timestamps
    end
  end
end
