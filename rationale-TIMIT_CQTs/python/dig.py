# TIMIT digger
# @description: Walk through the raw TIMIT dataset with a prompt (a specific word that is tagged in the dataset) and extract the audio portion for that word from all speakers of a specified dialect.
# @author: fabian schneider <f.schneider@donders.ru.nl>

import os
import sys

## settings
code_target_word = "suit"; # target word
code_target_dialect = "6"; # target dialect (6 = new york)
path_TIMIT = "/users/fabianschneider/downloads/TIMIT/data/lisa/data/timit/raw/TIMIT/"; # path to unarchived data set
path_output_conversion = "/users/fabianschneider/downloads/TIMIT/converted/"; # path to folder where converted sentence data are saved
path_output_snippets = "/users/fabianschneider/downloads/TIMIT/snippets/"; # path to folder where word snippets are saved
path_sph2pipe = "'/users/fabianschneider/downloads/sph2pipe_v2.5/sph2pipe'"; # command to run for sph2pipe

## find target subjects
code_target_speakers = [];
with open(os.path.join(path_TIMIT, 'DOC/SPKRINFO.TXT')) as f:
    spkrs = f.read().split("\n");
    for spkr in spkrs:
        spkrl = spkr.split("  "); # apparently, they don't \t the data...whew
        if len(spkrl) >= 8:
            if spkrl[2] == code_target_dialect:
                code_target_speakers.append(spkrl[0]);

## walk directory
for root, sub, files in os.walk(path_TIMIT):
    # make sure we skip people who don't speak the desired dialect
    folderrt = root.split("/");
    folder = folderrt[len(folderrt) - 1];
    if folder[1:] not in code_target_speakers:
        continue;

    # loop over files
    for file in files:
        if file[-4:] == '.WRD':
            with open(os.path.join(root, file)) as f:
                m = f.read().split("\n");
                for e in m:
                    t = e.split(" ");

                    if t[len(t) - 1] == code_target_word:
                        # get signal time stamps
                        tc_start = t[0];
                        tc_end = t[1];

                        # convert audio file
                        audfile = os.path.join(root, file[0:-4] + '.WAV');
                        tarfile = os.path.join(path_output_conversion, code_target_word + code_target_dialect + '_' + folder + '_' + file[0:-4] + '_c.WAV');
                        print("Converting %s." % (audfile));
                        os.system(path_sph2pipe + " -s " + tc_start + ":" + tc_end + " \"" + audfile + "\" \"" + tarfile + "\""); # requires sph2pipe

print("Process complete.");
