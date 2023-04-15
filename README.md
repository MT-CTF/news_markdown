# Markdown Server News

Once a player logs in to the server, they will be shown a dialog with server news. Depending on their language settings, different dialogues will be shown. This mod comes with sample news dialogues for English, Spanish, French and Italian.

All news is stored in markdown files in the world directory. They should be named "news_\<language code>.md". Any markdown content can be put in and it will be displayed correctly (hopefully), using the markdown2formspec module.

On the news dialogue is a checkbox asking the player if they want to see the news when they join next time. This can be toggled on and off through the formspec, or by doing `/toggle_news`. Players can also run `/news` to quickly access the server news.

If there are news updates (`news_markdown` will check the English news each time someone logs in for updates), players will either see the news pop up like normal or be told that there are updates in case they wish to see them.


## Custom CTF Changes
* Added an api for adding extra tabs to the news form
* Fixed crashes when news files aren't found
* Moved news files to <worldir>/news/ to keep things clean
* Removed the formspec showing on login to prevent collision with CTF formspecs
* Added a HUD message in addition to chat message notifying of new updates, made both of them ~green
* Redid the hash calculations to save to player meta, not a single modstorage key
* Changed formspec to take files from memory instead of reading the file every time.
* Added async function to load translation files
* Added command to reload translation files, allowing for live updates
