var ProfileNotesView = Ember.View.extend({
  templateName: "profile_notes",
  tagName: "section",
  classNames: ['profile-notes-ui'],
  noteDraft: "",

  insertElement: function() {
    this._insertElementLater(function() {
      var target = this._parentView.$("section.about").first();
      if (target.length === 0) target = this._parentView.$("section.details").first();
      console.log(target);
      this.$().insertAfter(target);
      this.loadNotes();
    }.bind(this));
  },

  loadNotes: function() {
    this.set('loading', true);
    Discourse.ajax("/profile_notes/load", {
      data: {target_id: this.get('user_id')}
    }).then(function(newJSON) {
      this.set('loading', false);
      this.set("notes", newJSON.notes);
      this.rerender();
    }.bind(this));
  },

  actions: {
    showAddNote: function() {
      this.set('showAddNote', true);
    },

    addNote: function() {
      var noteText = $.trim(this.$("textarea").val());
      if (!noteText) return;

      this.set('loading', true);
      this.set('showAddNote', false);
      Discourse.ajax("/profile_notes/add", {
        type: "POST",
        data: {target_id: this.get('user_id'),
               text: noteText, for_staff: this.$(".share-with-staff:checked").length}
      }).then(function(newJSON) {
        this.set('loading', false);
        this.set("notes", newJSON.notes);
        this.rerender();
      }.bind(this));

    },
    cancelAddNote: function() {
      this.set('showAddNote', false);
    }
  }
});

var injector = {
  renderProfileNotes: function() {
    console.log("rendering!", this);
    if (this.get('profileNotesView')) return;

    var view = this.createChildView(ProfileNotesView, {
      controller: this.get('controller'),
      user_id: this.get("user.id"),
      is_staff: Discourse.User.current().staff
    });
    view.insertElement();
    this.set('profileNotesView', view);
  }.on('didInsertElement'),

  updateProfileNotes: function(){
    if (!this.get('profileNotesView')) return;

    var view = this.get('profileNotesView');
    view.set("user_id", this.get("user.id"));
    view.set("notes", "");
    view.loadNotes();

  }.observes('user.loaded', 'user.id'),

  clearProfileNotesView: function() {
    if (this.get('profileNotesView')) {
      this.get('profileNotesView').destroy();
    }
  }.on('willClearRender')
};


export default {
  name: "inject-profiles-notes",

  initialize: function(container, application) {
    if (Discourse.SiteSettings.show_profile_notes_on_profile){
      var UserView  = container.lookupFactory('view:user');
      UserView.reopen(injector);
      console.log("done user view")
    }

    var AdminUserIndexView  = container.lookupFactory('view:admin-user-index');
    if (AdminUserIndexView){
      AdminUserIndexView.reopen(injector);
      console.log("injected AUI");
    } else if (container.lookupFactory('view:admin-user')){
      // no view but we have admin. let's create a view and inject
      console.log("Fallback: creating our own");
      var aui_view = Discourse.View.extend(injector, {
        didInsertElement: function () {
          console.log(arguments);
        }
      });
      container.register("view:admin-user-index", aui_view);
      Discourse.AdminUserIndexView = aui_view;
    }
  }
}