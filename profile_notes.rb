module ::ProfileNotesPlugin

  class ProfileNotes
    def initialize(target, user)
      @target = target
      @user = user
    end

    def get_notes(for_staff)
      case for_staff
      when true
        key = staff_key
        idx_key = "staff"
      when false
        key = notes_key
        idx_key = "user"
      end

      notes = ::PluginStore.get("profile_notes", key)

      return {notes: []} if notes.nil?

      notes[:notes].each_with_index do |note, idx|
        note[:note_index] = "#{idx_key}-#{idx}"
        if note[:topic_id]
          topic = Topic.find(note[:topic_id])
          note[:topic] = {
            id: topic.id,
            slug: topic.slug,
            title: topic.title
          }
        end
      end

      notes
    end

    def add_note(text, for_staff, extra = {})
      notes = get_notes(for_staff)
      notes[:notes] << {
        timestamp: Time.now.getutc,
        text: text,
        by: @user.id
      }.merge!(extra)

      key = for_staff ? staff_key : notes_key
      ::PluginStore.set("profile_notes", key, notes)
    end

    def edit_note(text, note_index, extra = {})
      for_staff = note_index.starts_with?('staff-')
      notes = get_notes(for_staff)

      notes[:notes].each do |note|
        if note[:note_index] == note_index
          note[:text] = text
          note[:timestamp] = Time.now.getutc
          note.merge!(extra)
        end
      end

      key = for_staff ? staff_key : notes_key
      ::PluginStore.set("profile_notes", key, notes)
    end

    def delete_note note_index
      for_staff = note_index.starts_with?('staff-')
      notes = get_notes(for_staff)

      notes[:notes] = notes[:notes].reject {|note| note[:note_index] == note_index }

      key = for_staff ? staff_key : notes_key
      ::PluginStore.set("profile_notes", key, notes)
    end


    def get_all_notes
      notes = get_notes(false)[:notes]

      if @user.staff?
        get_notes(true)[:notes].each_with_index do |note, idx|
          user = User.find(note[:by])
          note[:staff] = true
          note[:user] = {username: user.username, id: user.id, name: user.name}
          notes << note
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
