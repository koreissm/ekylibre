class AddVarietyAndBatchNumberInterventionParameters < ActiveRecord::Migration[4.2]
  def up
    add_column :intervention_parameters, :variety, :string
    add_column :intervention_parameters, :batch_number, :string
  end

  def down
    remove_column :intervention_parameters, :variety
    remove_column :intervention_parameters, :batch_number
  end
end
