# Preview

![preview1](https://cdn.discordapp.com/attachments/689969482520723464/694654776432132116/unknown.png)

![toolOptions](https://cdn.discordapp.com/attachments/689969482520723464/693919200841826365/unknown.png)

# How to use

[Гайд для 2HEAD на русском](https://youtu.be/JfGD9HfGwp4)

* Go to https://www.python.org/downloads/windows/ -> Click Latest Python 3 Release -> Scroll and find "Windows x86-64 executable installer" -> Start installer -> Check add to PATH

![install](https://i.imgur.com/WGL3CSw.png)

* [Download script](https://github.com/vadash/Path-of-Exile-modding-tool/archive/master.zip) Unpack somewhere and open folder

!AMD GPU! Remove `Path-of-Exile-modding-tool-master\extracted\Shaders` before running tool !AMD GPU!

New big p o e patch ? Delete folder *кeeр* before starting

![install](https://i.imgur.com/5fpbdHL.png)

* Run **Start.cmd** Provide path to ggpk (example, C:\games\poe\Content.ggpk)

![install](https://i.imgur.com/QFt4iM1.png)

Press Scan and wait

* Press insert (it will insert null shadow shader), wait, it should say "5 file inserted"

It will replace 2 shadow and 1 regular fog shader files, 2 delirium fog files.

* Automods -> PoeSmoother -> Check env, ot, epk, pet (top 4 boxes). Experimenta options are not stable. You are warned ;)

* Press modify, wait

* [optional] Use defragmentator (ggpk_defragment.exe) after big patches. Takes up to 10 minutes on SSD

# Credits

1 poemods (original repo)
https://github.com/poemods/Path-of-Exile-modding-tool

2 avs for exception list and fog idea

# Troubleshooting

Delete Content.ggpk

Download it again

Backup Content.ggpk

Delete folders CachedHLSLShaders, ShaderCacheD3D11 from poe root folder

Delete keep folder in Path-of-Exile-modding-tool

Try again
