# name: discourse-profile-notes
# about: leave notes on the profile of another person
# version: 0.1
# authors: Benjamin Kampmann

load File.expand_path("../profile_notes.rb", __FILE__)

# Without this line we can't lookup the constant inside the after_initialize blocks,
# probably because all of this is instance_eval'd inside an instance of
# Plugin::Instance.
ProfileNotesPlugin = ProfileNotesPlugin

after_initialize do
  # Rails Engine for managing notes on user profiles
  module ProfileNotesPlugin
    class Engine < ::Rails::Engine
      engine_name "profile_notes_plugin"
      isolate_namespace ProfileNotesPlugin
    end

    class ProfileNotesController < ActionController::Base
      include CurrentUser
      before_filter :ensure_current_user
      before_filter :has_note_index, only: [:edit, :delete]

      def loadNotes
        if params[:target_id].nil?
          render status: 400, json: false
          return
        end

        render json: notes.get_all_notes
      end

      def add
        if params[:target_id].nil? or params[:text].nil?
          render status: 400, json: false
          return
        end

        if current_user.staff? and !params[:for_staff].nil?
          notes.add_note(params[:text], params[:for_staff] == "1")
        else
          notes.add_note(params[:text], false)
        end
        render json: notes.get_all_notes
      end

      def edit
        notes.edit_note(params[:text], params[:note_index])
        render json: notes.get_all_notes
      end

      def delete
        notes.delete_note(params[:note_index])
        render json: notes.get_all_notes
      end

      private

      def render_forbidden
        render status: :forbidden, json: false
      end

      def ensure_current_user
        render_forbidden if current_user.nil?
      end

      def has_note_index
        render_forbidden if params[:note_index].nil?
      end

      def target
        @_target ||= User.find(params[:target_id])
      end

      def notes
        @_notes ||= ProfileNotesPlugin::ProfileNotes.new(target, current_user)
      end
    end
  end

  ProfileNotesPlugin::Engine.routes.draw do
    get '/load' => 'profile_notes#loadNotes'
    post '/add' => 'profile_notes#add'
    post '/edit' => 'profile_notes#edit'
    delete '/delete' => 'profile_notes#delete'
  end

  Discourse::Application.routes.append do
    mount ::ProfileNotesPlugin::Engine, at: '/profile_notes'
  end

end

# ProfileNote UI.
register_asset "javascripts/discourse/templates/profile_notes.js.handlebars"
register_asset "javascripts/profile_notes_ui.js"
register_asset "profile_notes.scss"

