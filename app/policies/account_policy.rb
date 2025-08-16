class AccountPolicy < ApplicationPolicy
  def show?
    @account_user.administrator? || @account_user.agent?
  end

  def cache_keys?
    @account_user.administrator? || @account_user.agent?
  end

  def limits?
    @account_user.administrator? || @account_user.agent?
  end

  def update?
    @account_user.administrator?
  end

  def update_active_at?
    true
  end

  def subscription?
    @account_user.administrator?
  end

  def checkout?
    @account_user.administrator?
  end

  def toggle_deletion?
    @account_user.administrator?
  end

  def kanban?
    @account_user.administrator? || @account_user.agent?
  end

  def kanban_stages?
    @account_user.administrator?
  end

  def kanban_board?
    @account_user.administrator? || @account_user.agent?
  end
end
