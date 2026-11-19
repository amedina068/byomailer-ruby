module Byomailer
  class Contacts < Resource
    # The contact that add returns. created? is true when the email was new (HTTP 201).
    class Added < Record
      def initialize(attributes, created:)
        super(attributes)
        @created = created
      end

      def created? = @created
    end

    # A page of contacts, newest first. lists, tags and topics take IDs.
    # Unsubscribed contacts are left out unless include_unsubscribed is true.
    def list(lists: nil, tags: nil, topics: nil, search: nil, include_unsubscribed: nil, per_page: nil, cursor: nil)
      page("/contacts", lists:, tags:, topics:, search:, include_unsubscribed:, per_page:, cursor:)
    end

    def find(id) = record(get("/contacts/#{id}"))

    # Adds the contact with this email to a list. A new email makes a new contact.
    # An existing email updates the contact. Each key of attributes becomes a
    # custom attribute.
    #
    # If an admin unsubscribed the contact, add subscribes the contact again.
    # An unsubscribe that the contact made stays. On an opt-in list, only a
    # contact that is new on the list gets the opt-in email.
    #
    #   contact = Byomailer.contacts.add("ana@example.com", list: 3, tags: ["vip"], attributes: { company: "Acme" })
    #   contact.created?
    def add(email, list:, name: nil, tags: nil, attributes: {})
      response = client.request(:post, "/lists/#{list}/contacts", json: contact_body(attributes, email:, name:, tags:))

      Added.new(response.body["data"], created: response.status == 201)
    end

    # Changes only the given fields. tags adds tags, remove_tags removes tags.
    # An update never changes the subscription. To subscribe a contact again,
    # use subscribe or add.
    def update(id, email: nil, name: nil, tags: nil, remove_tags: nil, attributes: {})
      record(patch("/contacts/#{id}", json: contact_body(attributes, email:, name:, tags:, remove_tags:)))
    end

    # A second call keeps the date of the first unsubscribe, so a retry is safe.
    def unsubscribe(id) = record(post("/contacts/#{id}/unsubscribe", idempotent: true))

    # Clears an unsubscribe that an admin or the API made. A subscribed contact
    # does not change, so a retry is safe. Raises ValidationError when the
    # contact unsubscribed through an email link (errors["contact"]) or when
    # the email is blacklisted (errors["email"]).
    def subscribe(id) = record(post("/contacts/#{id}/subscribe", idempotent: true))

    # Removes the contact from one list. The contact stays on its other lists.
    def remove(id, list:) = record(delete("/lists/#{list}/contacts/#{id}"))

    private
      # The API reads each unknown top-level field as a custom attribute.
      def contact_body(attributes, **fields)
        attributes.merge(fields.compact)
      end
  end
end
