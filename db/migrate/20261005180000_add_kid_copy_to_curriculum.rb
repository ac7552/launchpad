class AddKidCopyToCurriculum < ActiveRecord::Migration[8.0]
  def change
    # Student-facing wording at a 4th-grade reading level. The longer fields stay for teachers and parents.
    add_column :stages, :kid_name, :string
    add_column :stages, :emoji, :string
    add_column :stages, :kid_coding, :string
    add_column :stages, :kid_ai, :string
    add_column :stages, :kid_computer, :string
    add_column :stages, :kid_project, :string
    add_column :milestones, :kid_description, :string
  end
end
