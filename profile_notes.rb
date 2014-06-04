module ::ProfileNotesPlugin

  class ProfileNotes
    def initialize(target, user)
      @target = target
      @user = user
    end

    def get_notes(for_staff)
      key = for_staff ? staff_key() : notes_key()
      notes = ::PluginStore.get("profile_notes", key)

      return {notes: []} if notes.nil?

      notes[:notes].each_with_index do |note, idx|
        note[:note_index] = "user-#{idx}"
      end

      notes
    end

    def add_note(text, for_staff)
      notes = get_notes(for_staff)
      notes[:notes] << {
        timestamp: Time.now.getutc,
        text: text,
        by: @user.id
      }

      key = for_staff ? staff_key() : notes_key()
      ::PluginStore.set("profile_notes", key, notes)
    end

    def edit_note(text, note_index)
      for_staff = note_index.starts_with?('staff-')
      index = note_index.match(/\-(\d+)$/)[1].to_i
      notes = get_notes(for_staff)

      notes[:notes].each_with_index do |note, idx|
        if idx == index
          note[:text] = text
          note[:timestamp] = Time.now.getutc
        end
      end

      key = for_staff ? staff_key : notes_key
      ::PluginStore.set("profile_notes", key, notes)
    end

    def get_all_notes()
      notes = get_notes(false)[:notes]

      if @user.staff?
        get_notes(true)[:notes].each_with_index do |note, idx|
          user = User.find(note[:by])
          notes << {
              timestamp: note[:timestamp],
              text: note[:text],
              staff: true,
              user: {username: user.username, id: user.id, name: user.name},
              note_index: "staff-#{idx}"
          }
        end
      end
      # we want sort to inverted
      sorted = notes.sort {|a, b| b[:timestamp] <=> a[:timestamp] }
      return {notes: sorted}
    end

    private
    def notes_key
      "profile_notes_#{@target.id}_#{@user.id}"
    end
    def staff_key
      "profile_notes_#{@target.id}_staff"
    end
  end
end
