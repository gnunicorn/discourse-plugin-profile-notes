# name: discourse-poll
# about: polls
# version: 0.1
# authors: Vikhyat Korrapati

load File.expand_path("../poll.rb", __FILE__)

# Without this line we can't lookup the poll constant inside the after_initialize
# blocks, probably because all of this is instance_eval'd inside an instance of
# Plugin::Instance.
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

        options = Poll.get_details(post)

        unless options.keys.include? params[:option]
          render status: 400, json: false
          return
        end

        Poll.set_vote(post, current_user, params[:option])

        render json: Poll.serialize(post, current_user)
      end
    end
  end

  Poll::Engine.routes.draw do
    put '/' => 'poll#vote'
  end

  Discourse::Application.routes.append do
    mount ::Poll::Engine, at: '/poll'
  end

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
        details = Poll.get_details(self) || {}
        new_options = Poll.get_poll_options(self)
        details.each do |key, value|
          unless new_options.include? key
            details.delete(key)
          end
        end
        new_options.each do |key|
          details[key] ||= 0
        end
        Poll.set_details(self, details)
      end
    end
  end

  # Add poll details into the post serializer.
  PostSerializer.class_eval do
    attributes :poll_details
    def poll_details
      Poll.serialize(object, scope.user)
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
