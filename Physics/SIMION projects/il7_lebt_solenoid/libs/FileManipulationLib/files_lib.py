# This is a test script to manipulate files and paths
# Date: 2018/03/26
# Author: izpilab, gaudee, ehu
# Description:
#   We will extract the data from SIMION record file


#------------------------------ IMPORTS ----------------------------------#
from os import listdir
from os.path import isfile, join
import os

#------------------------------ FUNCTIONS --------------------------------#

def create_folder_with_path (path):
    if not os.path.exists(path):
        os.makedirs(path)


def get_files_from_dir (folder):
    ''' Given a path of a directory it returns a list with all the
        files inside it
        Inputs: the directory path
        Outputs: a list of filenames strings'''
    onlyfiles = [f for f in listdir(folder) if isfile(join(folder, f))]
    return onlyfiles

def get_absolute_path (path):
    ''' Given a relative path return the absolute one'''
    return os.getcwd() + "\\" + path
'''
    #-- Move the file to antother folder
    path = create_path_from_filename (FILENAME)
    create_folder_with_path (path)
    print 'path: ' + path
    try:
        os.rename(FILENAME, path + '\\' + FILENAME)
    except:
        print "The file already exists"
'''
