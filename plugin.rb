# name: discourse-poll
# about: polls
# version: 0.1
# authors: Vikhyat Korrapati

module ::Poll
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

  def self.vote_key(post, user)
    "poll_vote_#{post.id}_#{user.id}"
  end

  def self.details_key(post)
    "poll_options_#{post.id}"
  end
end

# Why is this needed?!
Poll = Poll

after_initialize do
  # Rails Engine for accepting votes.
  module Poll
    class Engine < ::Rails::Engine
      engine_name "poll"
      isolate_namespace Poll
    end

    class PollController < ActionController::Base
      include CurrentUser

      def vote
        if current_user.nil?
          render status: :forbidden, json: false
          return
        end

        if params[:post_id].nil? or params[:option].nil?
          render status: 400, json: false
          return
        end

        post = Post.find(params[:post_id])
        unless Poll::is_poll_post?(post)
          render status: 400, json: false
          return
        end

        options = ::PluginStore.get("poll", Poll.details_key(post))

        unless options.keys.include? params[:option]
          render status: 400, json: false
          return
        end

        # Get the user's current vote.
        vote = ::PluginStore.get("poll", Poll.vote_key(post, current_user))
        unless options.keys.include? vote
          vote = nil
        end

        options[vote] -= 1 if vote
        options[params[:option]] += 1

        ::PluginStore.set("poll", Poll.vote_key(post, current_user), params[:option])
        ::PluginStore.set("poll", Poll.details_key(post), options)

        render json: {options: options, selected: params[:option]}
      end
    end
  end

  Poll::Engine.routes.draw do
    put '/' => 'poll#vote'
  end

  Discourse::Application.routes.append do
    mount ::Poll::Engine, at: '/poll'
  end
end

after_initialize do
  # Starting a topic title with "Poll:" will create a poll topic. If the title
  # starts with "poll:" but the first post doesn't contain a list of options in
  # it we need to raise an error.
  Post.class_eval do
    validate :poll_topics_must_contain_a_list
    def poll_topics_must_contain_a_list
      return unless Poll.is_poll_post?(self)

      if Poll.get_poll_options(self).length == 0
        # We have a problem. TODO: i18n?
        self.errors.add(:raw, "must contain a list of poll options.")
      end
    end
  end

  # Save the list of options to PluginStore, but only if the post was created less
  # than 5 minutes ago. That way options get frozen after 5 minutes.
  Post.class_eval do
    after_save :save_poll_options_to_topic_metadata
    def save_poll_options_to_topic_metadata
      if Poll.is_poll_post?(self) and self.created_at >= 5.minute.ago
        details = ::PluginStore.get("poll", Poll.details_key(self)) || {}
        new_options = Poll.get_poll_options(self)
        details.each do |key, value|
          unless new_options.include? key
            details.delete(key)
          end
        end
        new_options.each do |key|
          details[key] ||= 0
        end
        ::PluginStore.set("poll", Poll.details_key(self), details)
      end
    end
  end

  # Add poll details into the post serializer.
  PostSerializer.class_eval do
    attributes :poll_details
    def poll_details
      vote = scope.user.nil? ? nil : ::PluginStore.get("poll", Poll.vote_key(object, scope.user))
      options = ::PluginStore.get("poll", Poll.details_key(object))
      {options: options, selected: vote}
    end
    def include_poll_details?
      Poll.is_poll_post?(object)
    end
  end
end

# Poll UI.
register_asset "javascripts/discourse/templates/poll.js.handlebars"
register_asset "javascripts/poll_ui.js"

register_css <<CSS

.poll-ui table {
  margin-bottom: 5px;
}

.poll-ui td.radio input {
  margin-left: -10px !important;
}

.poll-ui td {
  padding: 4px 8px;
}

.poll-ui td.option .option {
  float: left;
}

.poll-ui td.option .result {
  float: right;
  margin-left: 50px;
}

.poll-ui tr.active {
  background-color: #FFFFB3;
}

.poll-ui button {
  border: none;
}

CSS
