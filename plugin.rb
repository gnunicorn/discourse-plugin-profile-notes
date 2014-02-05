# name: discourse-poll
# about: polls
# version: 0.1
# authors: Vikhyat Korrapati

load File.expand_path("../poll.rb", __FILE__)

# Without this line we can't lookup the constant inside the after_initialize blocks,
# probably because all of this is instance_eval'd inside an instance of
# Plugin::Instance.
PollPlugin = PollPlugin

after_initialize do
  # Rails Engine for accepting votes.
  module PollPlugin
    class Engine < ::Rails::Engine
      engine_name "poll_plugin"
      isolate_namespace PollPlugin
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
        poll = PollPlugin::Poll.new(post)
        unless poll.is_poll?
          render status: 400, json: false
          return
        end

        options = poll.details

        unless options.keys.include? params[:option]
          render status: 400, json: false
          return
        end

        poll.set_vote!(current_user, params[:option])

        render json: poll.serialize(current_user)
      end
    end
  end

  PollPlugin::Engine.routes.draw do
    put '/' => 'poll#vote'
  end

  Discourse::Application.routes.append do
    mount ::PollPlugin::Engine, at: '/poll'
  end

  # Starting a topic title with "Poll:" will create a poll topic. If the title
  # starts with "poll:" but the first post doesn't contain a list of options in
  # it we need to raise an error.
  Post.class_eval do
    validate :poll_topics_must_contain_a_list
    def poll_topics_must_contain_a_list
      poll = PollPlugin::Poll.new(self)

      return unless poll.is_poll?

      if poll.options.length == 0
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
      poll = PollPlugin::Poll.new(self)
      if poll.is_poll? and self.created_at >= 5.minute.ago
        details = poll.details || {}
        new_options = poll.options
        details.each do |key, value|
          unless new_options.include? key
            details.delete(key)
          end
        end
        new_options.each do |key|
          details[key] ||= 0
        end
        poll.set_details! details
      end
    end
  end

  # Add poll details into the post serializer.
  PostSerializer.class_eval do
    attributes :poll_details
    def poll_details
      Poll.new(object).serialize(scope.user)
    end
    def include_poll_details?
      Poll.new(object).is_poll?
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
