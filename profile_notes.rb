module ::ProfileNotesPlugin

  class ProfileNotes
    def initialize(target, user)
      @target = target
      @user = user
    end

    def get_notes(for_staff)
      key = for_staff ? staff_key() : notes_key()
      notes = ::PluginStore.get("profile_notes", key)
      return notes if !notes.nil?

      return {notes: []}
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

    def get_all_notes()
      notes = get_notes(false)[:notes]
      if @user.staff?
        get_notes(true)[:notes].each do |note|
          user = User.find(note[:by])
          notes << {
              timestamp: note[:timestamp],
              text: note[:text],
              staff: true,
              user: {username: user.username, id: user.id, name: user.name}
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
