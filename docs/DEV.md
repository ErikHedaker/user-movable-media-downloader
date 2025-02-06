# Developer document

This document is for in-depth description with technical information about the project.

## Purpose of this project

The purpose and origin of this project was from working and helping visitors in a public library with IT related questions, and occasionally being asked if it's possible to download media like YouTube videos, e.g. listen to their music when they don't have Wifi available (and they don't have a service like a paid Spotify subscription which offer an offline-mode).

While easy for a person with more in-depth knowledge of CLI applications to setup and run in a terminal, it is hard to transfer that knowledge and explain the entire process of using a CLI application like yt-dlp directly for visitors who may not be as experienced with using computers.

So this project is intended to create an application with single entrypoint for installing and running, that can be run without requiring previously installed libraries, and can be executed in a sandboxed, user-restricted Windows environment that you find in publicly-accessible library computers.

## Project file structure

> ``start.cmd``
>
> Simplest way of starting an application in Windows, by using Windows batch script code to launch PowerShell script file with the correct configuration.

> ``src``
>
> Actual application code in the project, and the only directory and files required to run the application.\
> The files within are .ps1 files, PowerShell script files, and these execute in order to create the application.

> ``lib``
>
> Required portable executable files used by this project.

> ``tmp``
>
> Temporary work directory.

> ``docs``
>
> Documentation files, i.e. this document.

> ``test``
>
> Contains files to setup and launch a Windows Sandbox instance, in order to test the application in a similar and filesystem-safe virtual environment at home.

> ``README.md``
>
> Shortened documentation file with simple step-by-step instructions.

> ``.gitignore``
>
> Git repository managment file.

## Open-source, third-party software used

> ``yt-dlp``
>
> CLI application for downloading and extracting online media.

> ``ffmpeg``
>
> CLI application for converting between codecs and media file formats.

## Troubleshooting

> ### Problem:
>> Windows does not launch the application when you attempt to run it by double-clicking the ``start.cmd`` file.
>
> When you attempt to run the application with ``start.cmd``, it may block the execution of the script file.\
> While not a problem on a personal computer with administrator priviledges (where you can override the restriction), it may block the file from executing in a user-restricted environment.\
> This is due to the file having an unknown file signature from creating the script file on an external system (the developer's computer).\
> The file was then copied and moved over to the current system, potentially causing the issue.\
> And due to being an unknown signature, the system may have marked it as potentially dangerous.\
> To solve this issue, there are three options:
>
> ### Re-create the script file to generate a valid file signature
> Do the following steps:
>> Right-click the file, select ``Edit``. This will show you the actual script code instead of attempting to run the file. Copy all of this text.\
>> Create a new text file in the same directory (filename is not relevant). Paste the copied script code into this new text file.\
>> Then rename file and specifically change the extension of the file from ``.txt`` to ``.cmd`` (``.bat`` works as well).\
>> This is now a script file with a valid file signature to the current system, and should not be blocked by the system when ran.
>
> ### Execute the script directly in a terminal to circumvent certain Windows Explorer user-restrictions
> Do the following steps:
>> Launch a terminal in the current directory. You can do this by either starting the application ``cmd.exe`` (<em>Command Prompt</em>) or ``powershell.exe`` (<em>Windows PowerShell</em>).\
>> Go back to the project directory in Windows Explorer and copy the full path to the directory from the top address bar.\
>> Then in the terminal write the command ``cd `` and then paste the previously copied path and enter.\
>> You may need to write ``cd /d `` instead if you are using ``cmd.exe`` and the directory is on another system drive.\
>> You should now be in the project root directory (``user-movable-media-downloader``).\
>> You can then launch the application by writing ``.\start.cmd`` into the terminal.\
>> This should bypass the system file restriction from attempting to run an unknown script file by double-clicking in Windows Explorer.
>
> ### Executing the Main.ps1 PowerShell file in the terminal, skipping the Batch file entirely
> Do the following steps:
>> Starting from where the previous option left off, in the same terminal enter the following code:
>> ``powershell -ExecutionPolicy Bypass -File .\src\main.ps1 -ProjectRoot %cd%``