#!/usr/bin/python3
import binascii
import sys
import time
import re
import os

displaylabel=""

masterfilter_restrict=[
        "\.mat$"
        ]

masterfilter_exclude=[
    ]

condition={
   "my_default" : "Additive",
   "Opaque" : "OpaqueNoShadow",
   "OpaqueNoShadow" : "OpaqueNoShadow",
   "AlphaTest" : "AlphaTest",
   "AlphaBlend" : "AlphaBlend",
   "ShadowOnlyAlphaTest" : "Additive",
   "PremultipliedAlphaBlend" : "Additive",
   "MultiplicitiveBlend" : "Additive",
   "AlphaTestWithShadow" : "Additive",
   }

def execute(filename, backupfiledata, modifyggpk):
    filedata, encoding, bom = modifyggpk.stringcleanup(backupfiledata, "UTF-16-LE")
    filedatamod="Version 3"
    return filedatamod, encoding, bom

