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

    class ProfileNoteController < ActionController::Base
      include CurrentUser

      def addNote
      end
    end
  end

  ProfileNotesPlugin::Engine.routes.draw do
    put '/' => 'profile_notes#add'
  end

  Discourse::Application.routes.append do
    mount ::ProfileNotesPlugin::Engine, at: '/profile_notes'
  end

end

# ProfileNote UI.
register_asset "javascripts/discourse/templates/profile_notes.js.handlebars"
register_asset "javascripts/profile_notes_ui.js"

register_css <<CSS


CSS
