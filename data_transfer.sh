#!/bin/bash

if [ $1 == "scc" ]; then
  rsync -r --progress ~/Documents/Work/MIND/Manuscripts/MiCoNE-pipeline-paper/{data,figures} scc4:/rprojectnb/visant/dkishore/MiCoNE-pipeline-paper/
fi


if [ $1 == "local" ]; then
  rsync -r --progress scc4:/rprojectnb/visant/dkishore/MiCoNE-pipeline-paper/{data,figures} ~/Documents/Work/MIND/Manuscripts/MiCoNE-pipeline-paper/
fi
