module ::ProfileNotesPlugin

  class ProfileNotes
    def initialize(target, user)
      @target = target
      @user = user
    end

    def get_notes()
      notes = ::PluginStore.get("profile_notes", notes_key())
      return notes if !notes.nil?

      return {notes: []}
    end

    def add_note(text)
      notes = get_notes()
      notes[:notes] << {
        timestamp: Time.now.getutc,
        text: text,
        by: @user.id
      }

      ::PluginStore.set("profile_notes", notes_key(), notes)
    end

    private
    def notes_key
      "profile_notes_#{@target.id}_#{@user.id}"
    end
  end
end
