class AddCoordsToSponsor < ActiveRecord::Migration
  def change
    add_column :sponsors, :coordinates, :string
  end
end
