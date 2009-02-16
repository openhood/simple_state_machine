ActiveRecord::Schema.define(:version => 0) do
  create_table :chickens, :force => true do |t|
    t.string :name
    t.integer :age
    t.string :user_state
    t.string :validation_state
  end
end
