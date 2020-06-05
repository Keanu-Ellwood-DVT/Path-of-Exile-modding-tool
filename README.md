# Preview

You can make this (PoeSmoother preset)

![preview1](https://i.imgur.com/dbS7kl9.jpg)

Or this (BotSmoother preset)

![preview2](https://i.imgur.com/zNu2tDp.png)

![toolOptions](https://cdn.discordapp.com/attachments/672362352804495361/718074558233706536/unknown.png)

# Disclaimer

If you use GGPK to modify the game files, you are responsible for the consequences and risks. So far they didnt ban anyone for it ALONE in last 3 years. It was always + heavy RMT / using poe hud without limited user / caught on stream / botting + vmware / botting + many accs on same IP etc.

# How to use

[Гайд для 2HEAD на русском](https://youtu.be/JfGD9HfGwp4)

## Prepare phase (do it once)

* [Download python](https://www.python.org/ftp/python/3.7.7/python-3.7.7-amd64.exe) -> **Check add to PATH**

![install](https://i.imgur.com/WGL3CSw.png)

* [Download script](https://github.com/vadash/Path-of-Exile-modding-tool/archive/master.zip) Unpack somewhere and open script folder (Path-of-Exile-modding-tool-master)

* [Bots only] Copy `Path-of-Exile-modding-tool\optional\blackscreen` content to `Path-of-Exile-modding-tool\extracted`. Yes to override. Correct path will be `Path-of-Exile-modding-tool\extracted\Shaders\Renderer\Fog.ffx` for example. This will reduce gpu usage on vmware from 60% (100% spikes, 1sec lags) to 15% and no spikes 

* [Low end nvidia 1050 or below] Copy `Path-of-Exile-modding-tool\optional\nvidia` content to `Path-of-Exile-modding-tool\extracted`. Yes to override. Correct path will be `Path-of-Exile-modding-tool\extracted\Shaders\Renderer\Fog.ffx` for example. This will reduce gpu usage. You can use it on AMD but it may cause some lighting problems. Test it yourself

* [If you want to remove delirium fog] Copy `Path-of-Exile-modding-tool\optional\null delirium fog` content to `Path-of-Exile-modding-tool\extracted`. Edit "exclude" file, delete "League_Affliction/fogAttachment" line, save

* Run `Start.cmd` 

* Provide path to ggpk (example, C:\games\poe\Content.ggpk)

![install](https://i.imgur.com/QFt4iM1.png)

* Press Scan -> Wait for it to finish (Scan button is not red) -> Close tool

## After every patch

* Update Poe -> Close game

* Run `Start.cmd` 

* Automods -> PoeSmoother -> Tick everything you need

* Press modify (you dont need to wait, every action is added to queue. DONT click twice)

* Press insert button (you dont need to wait, every action is added to queue. DONT click twice)

* Now wait for ~10 minutes (SSD) / ~9000 minutes (HDD) until red background is gone

Skill and item MTX replacements: apply them 1 by 1 and test in multiple maps before applying another one! [Report crashes here](https://github.com/vadash/Path-of-Exile-modding-tool/issues) 

# Donate

If you like what you see you can support me <3

https://www.paypal.me/vadash

# Credits

* poemods (original repo) 95% work is his
https://github.com/poemods/Path-of-Exile-modding-tool

* avs for exception list and fog idea

* beta testers for bug testing <3

# Troubleshooting

Delete Content.ggpk

Download it again

Backup Content.ggpk

Delete folders CachedHLSLShaders, ShaderCacheD3D11 from poe root folder

Delete keep folder in Path-of-Exile-modding-tool

Now apply settings 1 by 1 and check where it crashed before

*Report* it here https://github.com/vadash/Path-of-Exile-modding-tool/issues or here https://www.ownedcore.com/forums/mmo/path-of-exile/poe-bots-programs/661920-path-of-exile-modding-tool-mods-1.html

## Permission denied

Right click poe folder -> Security -> Edit -> Add -> Advanced -> Find now -> Select "Everyone" -> Ok -> Click on "Everyone" -> Click allow full control -> Ok -> Ok

![access](https://i.imgur.com/nkdVySn.png)

## Failed to load ggpk invalid tag X

Close game -> Run included ggpk_defragment.exe -> Wait to finish
