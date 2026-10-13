> [!NOTE]
> This is a fork of [blaise-io/acelink](https://github.com/blaise-io/acelink) that adds native Apple Silicon (arm64) support. The Ace Stream engine only ships as an x86_64 binary, so the original app forced Docker to run a `linux/amd64` image, which relies on Rosetta. Future macOS releases will drop Rosetta, so this fork publishes a multi-arch image (`linux/amd64` and `linux/arm64`) in which the engine runs through [box64](https://github.com/ptitSeb/box64) on arm64, and no longer forces `amd64`.
>
> Many thanks to [Blaise Kal](https://github.com/blaise-io) for creating and maintaining Ace Link, and to everyone who contributed to it. The original project is released under the MIT license, and this fork keeps that license and the original copyright notice.

# Ace Link

Ace Link is a menu bar app that allows playing Ace Streams on macOS. 

Play an Ace Stream or Magnet in any media player by pasting the URL in the Ace Link menu, or open an acestream or magnet link in Ace Link.

## [Download for macOS](https://github.com/piazzean/acelink/releases/download/2.2.0/Ace.Link.2.2.0.dmg)

 - [Download current version](https://github.com/piazzean/acelink/releases)
 - Older releases of the original project: [blaise-io/acelink releases](https://github.com/blaise-io/acelink/releases)
 - Install the original (Intel-era) release using Homebrew: `brew install --cask ace-link`
 
Requires Docker and macOS Monterey (12.0) or later. Works natively on Apple Silicon and Intel Macs; on Apple Silicon the engine runs through box64 inside the container, so no Rosetta is needed.

<img src="acelink.png" width="350" alt="Ace Link" />

### Media players

Ace Link allows selecting your own media player. Ace Link does not transcode streams, so pick a player that supports popular audio and video codecs. VLC, IINA and MPV are free and open source media players that are able to play nearly anything. QuickTime and web browsers will play most streams, but not all. 

### Signing

Ace Link is an unsigned app because Apple does not allow p2p related applications. If your version of macOS does not allow opening unsigned applications, [follow these instructions to bypass this restriction](https://apple.stackexchange.com/a/240560).

### Ace Stream server only

If you just want to run the AceStream engine, you can do so without Ace Link:

```sh
docker run --rm -p 6878:6878 ghcr.io/piazzean/acelink
# now open http://<network ip>:6878/ace/getstream?id=<acestream id>
# or http://<network ip>:6878/ace/getstream?infohash=<magnet uri> in a player
```

If you want to use a custom acestream.conf: 
```
docker run --rm -p 6878:6878 -v "$(pwd)/acestream.conf:/opt/acestream/acestream.conf" ghcr.io/piazzean/acelink
```

### View Ace Link logs

1. Open Console.app
2. In the Console.app search field, type `Process: Ace Link`
3. Click on *Start* or *Start streaming*
4. Launch Ace Link and perform an action you want to debug
5. It should now start populating Console.app with debug information
