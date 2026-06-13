# Setup Guide (click-by-click, for non-technical owner)

This guide gets the app running on YOUR computer. Take it slow, one step at a time.

## Step 1 - Install the tools (one time)

1. **Install VS Code** (the code editor):
   https://code.visualstudio.com  -> Download -> install like any normal program.
2. **Install Flutter** (what builds the app):
   https://docs.flutter.dev/get-started/install -> pick your system (Windows/macOS)
   -> follow their steps. This is the longest part; be patient.
3. **Install Git** (saves/uploads your changes):
   https://git-scm.com/downloads -> install with default options.

To check it worked: open VS Code, open the Terminal menu -> New Terminal, type:

    flutter --version

If it prints a version number, you are good.

## Step 2 - Download this project into VS Code

1. In VS Code: press `Ctrl+Shift+P` (Windows) or `Cmd+Shift+P` (Mac).
2. Type: `Git: Clone` and press Enter.
3. Paste this project's web address:
   https://gitlab.com/entry-prep-app/THEETIFY-Entry_Test_Prep_App_Version-1.git
4. Pick a folder on your computer to save it.
5. When it asks, click "Open" to open the project.

## Step 3 - Add your secret keys

1. Find the file `.env.example` in the file list on the left.
2. Right-click it -> Copy, then Paste. Rename the copy to `.env`.
3. Open `.env` and paste your real keys (Supabase, Groq, etc.).
4. Save.

## Step 4 - Run the app

In the VS Code terminal, type these one at a time:

    flutter pub get
    flutter run -d chrome

The app opens in your Chrome browser. Done!

## Step 5 - Save and upload your changes

Whenever you change something:
1. Click the "Source Control" icon on the left (looks like branching lines).
2. Type a short message about what you changed.
3. Click the checkmark (Commit), then the "..." menu -> Push.

That uploads it to GitLab, and the website auto-updates.
