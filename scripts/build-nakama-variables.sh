#!/bin/bash

sed -i -e "s/use_production_nakama = false/use_production_nakama = true/" Main.gd
sed -i -e "s/NAKAMA_HOST/$NAKAMA_HOST/" Main.gd
sed -i -e "s/'NAKAMA_PORT'/$NAKAMA_PORT/" Main.gd

# Debugging
#cat Main.gd

# Clean-up server key for sed
#echo "$NAKAMA_SERVER_KEY"
#NAKAMA_SERVER_KEY=$(echo "$NAKAMA_SERVER_KEY" | sed -e 's/&/\\\&/g' | sed -e 's/\$/\\\$/g')

sed -i -e "s/NAKAMA_SERVER_KEY/${NAKAMA_SERVER_KEY}/" Main.gd

