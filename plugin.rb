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

      def loadNotes
        if current_user.nil?
          render status: :forbidden, json: false
          return
        end

        if params[:target_id].nil?
          render status: 400, json: false
          return
        end

        target = User.find(params[:target_id])
        notes = ProfileNotesPlugin::ProfileNotes.new(target, current_user)
        render json: notes.get_all_notes()
      end

      def add
        if current_user.nil?
          render status: :forbidden, json: false
          return
        end

        if params[:target_id].nil? or params[:text].nil?
          render status: 400, json: false
          return
        end

        target = User.find(params[:target_id])
        notes = ProfileNotesPlugin::ProfileNotes.new(target, current_user)
        if current_user.staff? and !params[:for_staff].nil?
          notes.add_note(params[:text], params[:for_staff] == "1")
        else 
          notes.add_note(params[:text], false)
        end
        render json: notes.get_all_notes()
      end
    end
  end

  ProfileNotesPlugin::Engine.routes.draw do
    get '/load' => 'profile_notes#loadNotes'
    post '/add' => 'profile_notes#add'
  end

  Discourse::Application.routes.append do
    mount ::ProfileNotesPlugin::Engine, at: '/profile_notes'
  end

end

# ProfileNote UI.
register_asset "javascripts/discourse/templates/profile_notes.js.handlebars"
register_asset "javascripts/profile_notes_ui.js"

register_css <<CSS
.profile-notes-ui {
  padding: 12px;
  border: 1px #CCC solid;
  color: #666;
}

.profile-notes-ui:after {
  content: " ";
  display: block;
  height: 0;
  clear: both;
  visibility: hidden;
}

.profile-notes-ui .note {
  border: 1px #CCC solid;
  margin: 5px 0;
  padding: 2px 10px;
  clear: both;
}

.profile-notes-ui .show-note {
    float: right;
    margin-bottom: 15px;
}

.profile-notes-ui .controls {
    display: block;
    margin-left: 5%;
    margin-bottom: 20px;
}

.profile-notes-ui textarea {
    width: 90%;
    margin-left: 5%;
    height: 70px;
}


.profile-notes-ui .note .timestamp,
.profile-notes-ui .note .shared,
.profile-notes-ui .note .private {
  font-size: 0.8em;
  color: #B3B3B3;
}

CSS
