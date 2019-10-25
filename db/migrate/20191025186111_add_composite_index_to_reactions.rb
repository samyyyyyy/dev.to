class AddCompositeIndexToReactions < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :reactions,
              [:user_id, :reactable_id, :reactable_type, :category],
              name: "index_reactions_on_reactable_user_category",
              algorithm: :concurrently
  end
end
