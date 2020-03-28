![preview](https://cdn.discordapp.com/attachments/689969482520723464/693124993525219368/unknown.png)

# IMPORTANT

Run defrag ggpk_defragment.exe after to make it compatible with tools like poesmoother, visual ggpk, etc

# Whats new

Updated to autoload exception list from exception.txt

Updated .env to 3.9

Remove delirium fog

# How to use

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

# End result (3.10 during delirium event)
![endresult](https://cdn.discordapp.com/attachments/343015052967673856/689917744887627889/unknown.png)

[Гайд для 2HEAD на русском](https://translate.google.com/translate?hl=&sl=auto&tl=ru&u=https%3A%2F%2Fgithub.com%2Fvadash%2FPath-of-Exile-modding-tool%2F)

# Troubleshooting

Delete Content.ggpk

Download it again

Backup Content.ggpk

Delete folders CachedHLSLShaders, ShaderCacheD3D11 from poe root folder

Delete keep folder in Path-of-Exile-modding-tool

Try again
