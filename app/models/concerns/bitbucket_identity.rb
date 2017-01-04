module BitbucketIdentity
  def assign_from_bitbucket_auth_hash(hash)
    ignored_fields = new_record? ? [] : %i(email)

    user_hash = {
      uid:         hash.fetch('uid'),
      nickname:    hash.fetch('uid'),
      email:       hash.fetch('info', {}).fetch('email', nil),
    }

    update_attributes(user_hash.except(*ignored_fields))
  end
end
