module Byomailer
  class EmailIdentities < Resource
    # A page of identities, newest first. identity_status is for example "verified".
    def list(identity_status: nil, per_page: nil, cursor: nil)
      page("/email-identities", identity_status:, per_page:, cursor:)
    end

    def find(id) = record(get("/email-identities/#{id}"))
  end
end
