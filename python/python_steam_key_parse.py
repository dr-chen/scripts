#!/usr/bin/env python

# Parse Steam Keys out of text files, create list, use Augmented Steam extension (https://augmentedsteam.com/) and copy paste the list into Steam key activation page: https://store.steampowered.com/account/registerkey

import datetime
import os
import re
import shutil
import sys

# Key List Folders
keyListsRaw = 'KeyListsRaw'
keyListsClean = 'KeyListsClean'

# Full paths to Key Lists
baseDirectory = os.path.join(os.path.dirname(os.path.realpath(__file__)), '')
fullPathKeyListRaw = os.path.join(os.path.dirname(os.path.realpath(__file__)), keyListsRaw, '')
fullPathKeyListClean = os.path.join(os.path.dirname(os.path.realpath(__file__)), keyListsClean, '')

# Find any .txt file in same dir as script, search for Steam Key pattern within file, output list of all found keys to KeyListsClean dir, keep original copy in KeyListsRaw dir
for rawFileName in os.listdir(baseDirectory):
	if ".txt" in rawFileName:
		print "Found %s" % rawFileName
		justFileName = ''.join(rawFileName.split())[:-4] #remove whitespace and last 4
		
		steamKeyMatches = []
		steamKeyRegex = re.compile("[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}")
		
		foundTextFile = baseDirectory + rawFileName
		textFile = open(foundTextFile, 'r')
		for line in textFile:
			steamKeyMatches += steamKeyRegex.findall(line)
		textFile.close()
		
		currentTime = datetime.datetime.now()
		cleanTime = currentTime.strftime('%Y%m%d_%H%M%S')

		parsedFinalPath = str(fullPathKeyListClean + cleanTime + justFileName + ".txt")
		outfile = open(parsedFinalPath, 'w')
		for line in steamKeyMatches:
			print line
			outfile.write(line + "\n")
		outfile.close()
		print "Created %s" % parsedFinalPath
		
		rawFinalPath = str(fullPathKeyListRaw + cleanTime + rawFileName)
		shutil.move(foundTextFile, rawFinalPath)
		print "Moved %s to %s" % (rawFileName, rawFinalPath)