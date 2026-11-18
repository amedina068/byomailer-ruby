module Byomailer
  class EmailTemplates < Resource
    # A page of templates, newest first. archived: true gives only the archived
    # templates. is_default filters on the default flag.
    def list(archived: nil, is_default: nil, per_page: nil, cursor: nil)
      page("/email-templates", archived:, is_default:, per_page:, cursor:)
    end

    def find(id) = record(get("/email-templates/#{id}"))

    # Raises NotFoundError when no template is the default.
    def default = record(get("/email-templates/default"))
  end
end
