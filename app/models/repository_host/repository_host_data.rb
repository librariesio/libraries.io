# frozen_string_literal: true

# This class is meant to be a facade over the raw upstream data coming
# from the different repository hosts' repository data. It's main goal
# is to standardize the output from each repository host into a concrete
# set of data so we can make sure the raw data is being mapped to the same
# schema within the Libraries.io models and code.
RepositoryHost::RepositoryHostData = Struct.new(
  :archived, :default_branch, :description, :fork, :full_name, :has_issues, :has_wiki, :homepage, :host_type,
  :keywords, :language, :license, :name, :owner, :parent, :is_private, :repository_uuid, :scm, :repository_size,
  keyword_init: true
) do
  def to_repository_attrs
    attrs = {
      default_branch: default_branch,
      description: description,
      full_name: full_name,
      has_issues: has_issues,
      has_wiki: has_wiki,
      homepage: homepage,
      host_type: host_type,
      keywords: keywords,
      language: language,
      license: formatted_license,
      name: name,
      private: is_private,
      scm: scm,
      size: repository_size,
      uuid: repository_uuid,
    }
    attrs[:source_name] = source_name if fork

    attrs
  end

  def formatted_license
    if license
      Project.format_license(license)
    end
  end

  def source_name
    parent[:full_name] if fork
  end
end
