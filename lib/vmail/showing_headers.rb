module Vmail
  module ShowingHeaders
    # id_set may be a range, array, or string
    def fetch_row_text(uid_set)
      log "Fetch_row_text: #{uid_set.inspect}"
      if uid_set.is_a?(String)
        uid_set = uid_set.split(',')
      end
      if uid_set.to_a.empty?
        log "- empty set"
        return ""
      end
      messages = uid_set.map {|uid| Message[mailbox: @mailbox, uid: uid] }
      message.map {|m| format_header_for_list(m)}
    end

    def fetch_and_cache_headers(id_set)
      results = reconnect_if_necessary do 
        # TODO check if we've cached it?
        @imap.fetch(id_set, ["FLAGS", "ENVELOPE", "RFC822.SIZE", "UID" ])
      end
      if results.nil?
        error = "Expected fetch results but got nil"
        log(error) && raise(error)
      end
      # TODO see if we can get message_uid (the other uid) ?
      results.each do |x| 
        # Store in sqlite3
        subject = Mail::Encodings.unquote_and_convert_to(envelope.subject, 'UTF-8')
        params = {
          subject: (subject || ''),
          flags: flags.join(','),
          date: date.to_s,
          size: size,
          sender: address,
          uid: uid,
          mailbox: @mailbox,
          # reminder to fetch these later
          rfc822: nil, 
          plaintext: nil 
        }
        DB[:messages].insert params
      end
    end

    def format_header_for_list(message)
      envelope = fetch_data.attr["ENVELOPE"]
      address_struct = if @mailbox == mailbox_aliases['sent'] 
                         structs = envelope.to || envelope.cc
                         structs.nil? ? nil : structs.first 
                       else
                         envelope.from.first
                       end
      address = if address_struct.nil?
                  "Unknown"
                elsif address_struct.name
                  "#{Mail::Encodings.unquote_and_convert_to(address_struct.name, 'UTF-8')} <#{[address_struct.mailbox, address_struct.host].join('@')}>"
                else
                  [Mail::Encodings.unquote_and_convert_to(address_struct.mailbox, 'UTF-8'), Mail::Encodings.unquote_and_convert_to(address_struct.host, 'UTF-8')].join('@') 
                end
      if @mailbox == mailbox_aliases['sent'] && envelope.to && envelope.cc
        total_recips = (envelope.to + envelope.cc).size
        address += " + #{total_recips - 1}"
      end
      formatted_date = if message.date.year != Time.now.year
                         message.date.strftime "%b %d %Y" 
                       else 
                         message.date.strftime "%b %d %I:%M%P"
                       end
      mid_width = @width - 38
      address_col_width = (mid_width * 0.3).ceil
      subject_col_width = (mid_width * 0.7).floor
      row_text = [ format_flags(message.flags).col(2),
                   (formatted_date || '').col(14),
                   address.col(address_col_width),
                   message.subject.col(subject_col_width), 
                   number_to_human_size(message.size).rcol(7), 
                   message.uid ].join(' | ')
    end

    def with_more_message_line(res, start_seqno)
      log "Add_more_message_line for start_seqno #{start_seqno}"
      if @all_search
        return res if start_seqno.nil?
        remaining = start_seqno - 1
      else # filter search
        remaining = (@ids.index(start_seqno) || 1) - 1
      end
      if remaining < 1
        log "None remaining"
        return "Showing all matches\n" + res
      end
      log "Remaining messages: #{remaining}"
      ">  Load #{[100, remaining].min} more messages. #{remaining} remaining.\n" + res
    end

  end
end
