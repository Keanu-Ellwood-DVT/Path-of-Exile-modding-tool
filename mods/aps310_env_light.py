#!/usr/bin/python3
import binascii
import sys
import time
import re
import os

displaylabel=""

masterfilter_restrict=[
    ]

masterfilter_exclude=[
    ]

def execute(filename, backupfiledata, modifyggpk):
    filedata, encoding, bom = modifyggpk.stringcleanup(backupfiledata, "UTF-16-LE")

    filedatamod = re.sub(r"""  "directional_light": \{[]\t\n\r !"#$%&'()*+,./0-9:;<=>?@\[\\_`a-z{|}~^-]{1,9999}?  \},""", """  "directional_light": {
    "shadows_enabled": false,
    "colour": [
      1.0,
      1.0,
      1.0
    ],
    "multiplier": 0.4,
    "phi": 2,
    "theta": 2
  },""", filedata)

    filedatamod = re.sub(r"""  "player_light": \{[]\t\n\r !"#$%&'()*+,./0-9:;<=>?@\[\\_`a-z{|}~^-]{1,9999}?  \},""", """  "player_light": {
    "shadows_enabled": false,
    "colour": [
      1.0,
      1.0,
      1.0
    ],
    "intensity": 1.0,
    "penumbra": 0.0
  },""", filedatamod)

    return filedatamod, encoding, bom
