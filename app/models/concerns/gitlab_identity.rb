module GitlabIdentity
  def assign_from_gitlab_auth_hash(hash)
    ignored_fields = new_record? ? [] : %i(email)

    user_hash = {
      uid:         hash.fetch('uid'),
      nickname:    hash.fetch('info', {}).fetch('username'),
      email:       hash.fetch('info', {}).fetch('email', nil),
    }

    update_attributes(user_hash.except(*ignored_fields))
  end
end
