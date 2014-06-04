var ProfileNotesView = Ember.View.extend({
  templateName: "profile_notes",
  tagName: "section",
  classNames: ['profile-notes-ui'],
  noteDraft: "",

  insertElement: function() {
    this._insertElementLater(function() {
      var target = this._parentView.$("section.about");
      this.$().insertAfter(target);
      this.loadNotes();
    }.bind(this));
  },

  loadNotes: function() {
    this.set('loading', true);
    Discourse.ajax("/profile_notes/load", {
      data: {target_id: this.get('user_id')}
    }).then(function(newJSON) {
      console.log(newJSON.notes);
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
    },

    showEditNote: function(note) {
      this.set('note', note);
      this.set('showEditNote', true);
    },
    editNote: function() {
      var noteText = $.trim(this.$("textarea").val());

      this.set('loading', true);
      this.set('showEditNote', false);
      Discourse.ajax("/profile_notes/edit", {
        type: "POST",
        data: {note_index: this.get('note').note_index,
                target_id: this.get('user_id'),
                text: noteText }
      }).then(function(newJSON) {
        this.set('loading', false);
        this.set("notes", newJSON.notes);
        this.rerender();
      }.bind(this));
    },
    cancelEditNote: function() {
      this.set('showEditNote', false);
    },
    deleteNote: function(note) {
      Discourse.ajax("/profile_notes/delete", {
        type: "DELETE",
        data: {note_index: note.note_index,
                target_id: this.get('user_id')}
      }).then(function(newJSON) {
        this.set("notes", newJSON.notes);
        this.rerender();
      }.bind(this));
    }
  }
});

Discourse.UserView.reopen({
  renderProfileNotes: function() {
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
});
