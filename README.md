![ram](https://cdn.discordapp.com/attachments/689969482520723464/695970176046202920/unknown.png)

![preview](https://i.imgur.com/dbS7kl9.jpg)

![toolOptions](https://i.imgur.com/b68cnDM.png)

# How to use

[Гайд для 2HEAD на русском](https://youtu.be/JfGD9HfGwp4)

* Go to https://www.python.org/downloads/windows/ -> Click Latest Python 3 Release -> Scroll and find "Windows x86-64 executable installer" -> Start installer -> **Check add to PATH**

![install](https://i.imgur.com/WGL3CSw.png)

* [Download script](https://github.com/vadash/Path-of-Exile-modding-tool/archive/master.zip) Unpack somewhere and open script folder (Path-of-Exile-modding-tool-master)

!AMD GPU! Remove `Path-of-Exile-modding-tool-master\extracted\Shaders` before running tool !AMD GPU!

New big p o e patch ? Delete folder *кeeр* before starting

![install](https://i.imgur.com/5fpbdHL.png)

* Run **Start.cmd** 

Provide path to ggpk (example, C:\games\poe\Content.ggpk)

![install](https://i.imgur.com/QFt4iM1.png)

Press Scan and wait

* Automods -> PoeSmoother -> Check everything you need except [bot], [optional], [experimental]

* Press modify, wait for script to finish (~10 minutes with SSD)

* Press insert button (it will replace 2 shadow and 1 regular fog shader, 2 delirium fog, 2 delve lighting files), wait, it should say "X file inserted", X < 50. If you dont press insert button (not keyboard key) after all modifications you will get bug like this in delirium

![bug](https://i.imgur.com/q7tW2wr.png)

* [optional] Use included defragmentator (ggpk_defragment.exe) after big patches. Takes up to 10 minutes on SSD

P.S. You still need SSD to play poe

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

Now apply settings 1 by 1 and check where it crashed before

## Permission denied

Right click poe folder -> Security -> Edit -> Add -> Advanced -> Find now -> Select "Everyone" -> Ok -> Click on "Everyone" -> Click allow full control -> Ok -> Ok

![access](https://i.imgur.com/nkdVySn.png)
