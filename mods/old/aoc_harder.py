import re

'''

restriction "^\./Metadata/Effects/Environment/.*\.aoc$"
restriction "^\./Metadata/Effects/Microtransactions/.*\.aoc$"
restriction "^\./Metadata/Effects/Spells/.*\.aoc$"
restriction "^\./Metadata/Terrain/Doodads/.*\.aoc$"

'''

condition=[
   "ClientAnimationController",
   #"SkinMesh",
   "FixedMesh",
   "BoneGroups",
   #"ParticleEffects",
   #"DecalEvents",
   #"Lights",
   #"Sounds",
   #"WindEvents",
   ]

def execute(filename, backupfiledata, modifyggpk):
    filedata, encoding, bom = modifyggpk.stringcleanup(backupfiledata, "UTF-16-LE")
    filedatamod=filedata
    mi=re.finditer(r'(\w+)[\t\r\n ]*\{.*?\}[\t\r ]*(\n|$)', filedata, flags=re.DOTALL)
    for mii in mi :
        tagis=mii.group(1)
        if tagis not in condition :
            filedatamod=re.sub(tagis+r'[\t\r\n ]*\{.*?\}[\t\r ]*(\n|$)', tagis+r'\r\n{\r\n}\r\n', filedatamod, flags=re.DOTALL)
    return filedatamod, encoding, bom

