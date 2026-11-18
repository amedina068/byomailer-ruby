module Byomailer
  # One page of a cursor list. Enumerate it, or walk to the next page.
  #
  #   page = Byomailer.contacts.list(per_page: 100)
  #   page.each { |contact| puts contact.email }
  #   page.next_page if page.next_page?
  #
  # each_record walks every page:
  #
  #   Byomailer.contacts.list(per_page: 100).each_record { |contact| puts contact.email }
  class Page
    include Enumerable

    attr_reader :records, :meta

    def initialize(records, meta, &next_page)
      @records = Record.wrap(records || [])
      @meta = Record.wrap(meta || {})
      @next_page = next_page
    end

    def each(&) = records.each(&)

    def next_cursor
      meta[:next_cursor]
    end

    def next_page?
      !next_cursor.nil?
    end

    def next_page
      @next_page.call(next_cursor) if next_page?
    end

    # Enumerates the records of this page and of each page after it.
    # Without a block, returns an Enumerator.
    def each_record(&block)
      return enum_for(:each_record) unless block

      page = self
      while page
        page.each(&block)
        page = page.next_page
      end
    end
  end
end
