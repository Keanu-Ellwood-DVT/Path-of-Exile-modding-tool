#!/usr/bin/python3
import binascii
import sys
import time
import re
import os

displaylabel=""

masterfilter_restrict=[
        "\.env$"
    ]

masterfilter_exclude=[
    ]

def execute(filename, backupfiledata, modifyggpk):
    filedata, encoding, bom = modifyggpk.stringcleanup(backupfiledata, "UTF-16-LE")
    filedatamod=re.sub(r'"shadows_enabled": true,', r'"shadows_enabled": false,', filedata)
    filedatamod=re.sub(r'"exp_fog_is_enabled": true,', r'"exp_fog_is_enabled": false,', filedatamod)
    filedatamod=re.sub(r'"player_environment_ao": "Metadata/Effects/weather_attachments/rain/rain.ao",', r'"player_environment_ao": "",', filedatamod)
    return filedatamod, encoding, bom

