#!/usr/bin/env bash
# 00-env.sh - shared settings. `source` this before the other demo scripts:
#   source demos/00-env.sh
#
# WarGames (1982) theme. "Shall we play a game?"

export PROJECT_ID="simplifymycloud-dev"
export REGION="us-central1"
export PREFIX="wargames"

# Secret containers (created by Terraform).
export LAUNCH_SECRET="${PREFIX}-launch-code"        # WOPR's nuclear launch code
export WARPLAN_SECRET="${PREFIX}-cmek-warplan"      # CMEK "war plan" - kill switch demo
export BACKDOOR_SECRET="${PREFIX}-joshua-backdoor"  # Falken's backdoor password - rotation demo

# The least-privilege consumer identity: WOPR (created by Terraform).
export WOPR_SA="${PREFIX}-wopr@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud config set project "$PROJECT_ID" >/dev/null 2>&1

echo "project = $PROJECT_ID | region = $REGION | prefix = $PREFIX"
echo 'GREETINGS PROFESSOR FALKEN. Shall we play a game?'
