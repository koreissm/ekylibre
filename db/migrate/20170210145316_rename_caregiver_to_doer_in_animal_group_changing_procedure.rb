class RenameCaregiverToDoerInAnimalGroupChangingProcedure < ActiveRecord::Migration[4.2]
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'doer'
          FROM interventions
          WHERE (iparam.reference_name = 'caregiver'
            AND interventions.procedure_name = 'animal_group_changing'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
      dir.down do
        execute <<-SQL
        UPDATE
          intervention_parameters AS iparam
          SET reference_name = 'caregiver'
          FROM interventions
          WHERE (iparam.reference_name = 'doer'
            AND interventions.procedure_name = 'animal_group_changing'
            AND iparam.intervention_id = interventions.id)
        SQL
      end
    end
  end
end
