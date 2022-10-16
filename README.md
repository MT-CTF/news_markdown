# Markdown Server News

Once a player logs in to the server, they will be shown a dialog with server news. Depending on their language settings, different dialogues will be shown. This mod comes with sample news dialogues for English, Spanish, French and Italian.

All news is stored in markdown files in the world directory. They should be named "news_\<language code>.md". Any markdown content can be put in and it will be displayed correctly (hopefully), using the markdown2formspec module.

On the news dialogue is a checkbox asking the player if they want to see the news when they join next time. This can be toggled on and off through the formspec, or by doing `/toggle_news`. Players can also run `/news` to quickly access the server news.
