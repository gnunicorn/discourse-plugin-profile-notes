module ::Poll

  # TODO: This needs to be a class.

  def self.is_poll_post?(post)
    if !post.post_number.nil? and post.post_number > 1
      # Not a new post, and also not the first post.
      return false
    end

    topic = post.topic

    # Topic is not set in a couple of cases in the Discourse test suite.
    return false if topic.nil?

    if post.post_number.nil? and topic.highest_post_number > 0
      # New post, but not the first post in the topic.
      return false
    end

    topic.title =~ /^poll:/i
  end

  def self.get_poll_options(post)
    cooked = PrettyText.cook(post.raw, topic_id: post.topic_id)
    Nokogiri::HTML(cooked).css("ul:first li").map {|x| x.children.to_s.strip }.uniq
  end

  def self.get_details(post)
    ::PluginStore.get("poll", Poll.details_key(post))
  end

  def self.set_details(post, details)
    ::PluginStore.set("poll", Poll.details_key(post), details)
  end

  def self.get_vote(post, user)
    ::PluginStore.get("poll", Poll.vote_key(post, user))
  end

  def self.set_vote(post, user, option)
    # Get the user's current vote.
    details = Poll.get_details(post)
    vote = Poll.get_vote(post, user)
    vote = nil unless details.keys.include? vote

    details[vote] -= 1 if vote
    details[option] += 1

    ::PluginStore.set("poll", Poll.vote_key(post, user), option)
    Poll.set_details(post, details)
  end

  def self.serialize(post, user)
    {options: Poll.get_details(post), selected: (user.nil? ? nil : Poll.get_vote(post, user))}
  end

  private

  def self.vote_key(post, user)
    "poll_vote_#{post.id}_#{user.id}"
  end

  def self.details_key(post)
    "poll_options_#{post.id}"
  end
end
