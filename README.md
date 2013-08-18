worm.love
=========

action game written in lua/love

how to set it up
================

You'll need to install the Lua programming language, and the Love game development framework. If you're using Linux, you probably know how to do this (use your package manager). If you're using Windows, download Lua from http://code.google.com/p/luaforwindows/downloads/list and Love from http://love2d.org/ . After you've installed them, you should be able to run worm.love. To do that...

how to actually run worm.love
=============================

If you're using Linux, you probably know how to do this (open a terminal, then type "love /path/to/worm.love" without quotes). If you're using Windows, I'm not sure how you'd do that, but it would probably be something like this:

1. Open the command prompt (cmd.exe). It should be in your start menu if you search for "command" or something.

2. Type in the path to love.exe (maybe it'd be something like "C:\Program Files\Love\love.exe"). You can use the tab key to auto-complete a half-typed directory or file name. If the path has spaces, it should be quoted.

3. Type a space and then type the path to the worm.love folder. Make sure you type the path to the folder itself, not anything within it.

4. Press enter. The game should start.

5. If you exit the game and want to start it again, all you have to do is press the up arrow key in cmd.exe, and it will retype the command you pressed before. That way you don't have to re-type it all over again.

That should work. I haven't tried it so I can't guarantee it.

Alternatively, you could just zip the contents of the worm.love folder up, name it "worm.love" and then double-click it. That might be easier but then if you change anything in the actual folder called worm.love, it won't affect the worm.love zipped file.

If you try that and get an error about the file not being packaged correctly, it means that you zipped the folder instead of just the contents of the folder. Make sure you select all the files inside the worm.love folder, then right-click and zip that. It should work then.
