module Byomailer
  class EmailLogs < Resource
    # A page of logs, newest first. recipient matches a part of the address.
    def list(status: nil, operation: nil, recipient: nil, per_page: nil, cursor: nil)
      page("/email-logs", status:, operation:, recipient:, per_page:, cursor:)
    end

    def find(id) = record(get("/email-logs/#{id}"))
  end
end
