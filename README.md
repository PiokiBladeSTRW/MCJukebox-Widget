# Minecraft Themed Jukebox Widget [Plasma]

## [DISCLAIMER: This project is not affiliated with Mojang AB or Microsoft]

This Project contains the source code for a Plasma based Widget of a Minecraft themed Music Player! On the bottom right corner sits a Jukebox, click it and it pops open with full playback control.
Originally made as a personal project, until further development led me to polish the code way more than I needed to, leading me to publish the source code, in hopes to learn more.

# Features

- **Playback:** Background Music play that auto starts on boot if left on mid-play
-  **Minecraft UI:** Fully themed Minecraft UI.
-  **Playlists:** Complete playlist management with dynamic cover art mapping support.
- **Search:** Search across all tracks inside your configured music directory.
- **Compact:** Doesn't take up much space in Desktop, even when Opened
- **Fast & Performant:** Heavily optimized to ensure minimal CPU and Memory waste


## Backend

This Project runs on *MPD & MPC* for the music playing. For advanced users, changing up MPD directory, host and port support is provided.

## Installation & Compilation

This project is uploaded just as a source code and not as an installable or a distributed widget due to the usage of Copyrighted Materials [*Minecraft artwork*]. This project in no way seeks Commercial Gain; It was made purely as a personal project and I decided to share it. If you wish to install it onto your system, follow the process below:

### System Requirements:
1) A Device running the Linux Distro **Ubuntu** with the Desktop Envrionment of **KDE Plasma**

### Installation Process:
1. Download the Repository : 
> git clone https://github.com/PiokiBladeSTRW/MCJukebox-Widget
2. Download the Required Backend :
 > sudo apt install mpc mpd 
3. Download the Required Dev Libraries for Compiling:
> sudo apt install cmake qt6-base-dev qt6-declarative-dev libkf6plasma-dev extra-cmake-modules 
 4. Compile the Code :
 > cmake -B build; cmake --build build; sudo cmake --install build
 
 Then hop onto your desktop in Edit Mode and you'll find Minecraft Jukebox Widget. Position it and enjoy :)

## License and Copyright Disclaimer

**Source Code:** The Source Code of this project is Distributed under the MIT License. See `LICENSE` for more information

**Assets & Artwork:** All Minecraft related textures and imagery included in this repository are the intellectual property of Mojang AB and Microsoft Corporation. They are used purely for decorative, non-commercial fan purposes and are **NOT** covered by the MIT License. This project is not affiliated with, endorsed by, or sponsored by Mojang or Microsoft. 

## Personal Note

This project is the first one I have ever made publicly available despite my constant fear of crude criticism and toxicity. I absolute would not mind my code being criticized and receiving suggestions on how I can improve.
This was my first time making a project that spanned multiple languages; the C++ class is pretty bare bones and might be obvious in it so as I only made it because every other method for achieving the specific goal felt more like a band-aid than a genuine fix.
### Contribution
I haven't been a part of the OpenSource community long enough to fully understand the pipeline of code contributions. Furthermore so, I have spent a good while working on this that I want to call it done for the time being, hence contributions are generally discouraged, make better use of your time.

## Future

In the Future I hope to make the code less depended on the Shell and more so directly on MPD; But that'll require a lot of rewriting so not anytime soon
