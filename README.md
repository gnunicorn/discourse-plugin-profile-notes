### TODO

* i18n
* Editing options within the first 5 minutes updates them but doesn't reflect that in the UI until a page refresh because the new options returned by the server aren't actually saved onto the post object. Figure out a way to work around this.
* PluginStore updates aren't atomic, this might be dangerous.
* Show an error message or something rather than infinite loading if a guest tries to vote.
