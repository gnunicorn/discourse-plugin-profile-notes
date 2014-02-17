module ::ProfileNotesPlugin

  class ProfileNote
    def initialize(user)
      @user = user
    end

    def options
      cooked = PrettyText.cook(@post.raw, topic_id: @post.topic_id)
      Nokogiri::HTML(cooked).css("ul:first li").map {|x| x.children.to_s.strip }.uniq
    end

    def details
      @details ||= ::PluginStore.get("poll", details_key)
    end

    def set_details!(new_details)
      ::PluginStore.set("poll", details_key, new_details)
      @details = new_details
    end

    def get_vote(user)
      user.nil? ? nil : ::PluginStore.get("poll", vote_key(user))
    end

    def set_vote!(user, option)
      # Get the user's current vote.
      vote = get_vote(user)
      vote = nil unless details.keys.include? vote

      new_details = details.dup
      new_details[vote] -= 1 if vote
      new_details[option] += 1

      ::PluginStore.set("poll", vote_key(user), option)
      set_details! new_details
    end

    def serialize(user)
      {options: details, selected: get_vote(user)}
    end

    private
    def details_key
      "poll_options_#{@post.id}"
    end

    def vote_key(user)
      "poll_vote_#{@post.id}_#{user.id}"
    end
  end
end
