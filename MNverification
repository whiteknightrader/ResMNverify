#!/bin/bash

#USAGE: ./vote.sh

#Make sure jq is installed
checkjq() {
    if hash jq 2>/dev/null; then
        echo "jq installed... proceeding"
    else
        sudo apt install jq
    fi
}

#Make sure shasum256 is installed
checkshasum() {
    if hash sha256sum 2>/dev/null; then
        echo "sha256sum installed... proceeding"
    else
        echo "Hmmm... couldn't find sha256sum... exiting"
    exit
    fi
}

#Make sure jq is installed
checkcurl() {
    if hash curl 2>/dev/null; then
        echo "curl installed... proceeding"
    else
        sudo apt install curl
    fi
}

checkjq
checkcurl
checkshasum
cd ~
UUID=$(cat resuser/resnode/config/config.json | jq -r .super.nodeid)
HASHED_UUID=$(echo -n $UUID | sha256sum | cut -d" " -f1)
TADDR=$(curl -s https://resnode.resistance.io/api/nodes | jq -r '.[] | select(.hashed_uuid=='\"$HASHED_UUID\"') | .taddr')

if [ -z "$TADDR" ]
then
      echo "Something went wrong... Please try again later."
      exit
fi

echo -n "What GitHub Issue number are you voting for?: "
read ISSUE_NUMBER

re='^[0-9]+$'
if ! [[ $ISSUE_NUMBER =~ $re ]] ; then
   echo "Error: Not a number. Please try again with a valid GitHub issue number." >&2; exit 1
fi

echo -n "Do you vote (Y)es or (N)o to the proposal in GitHub issue $ISSUE_NUMBER ? (Y/N): "
read VOTE_VALUE

if [[ "$VOTE_VALUE" != "Y" ]] && [[ "$VOTE_VALUE" != "N" ]]
then
    echo "Invalid vote. You must choose either Y or N. Please try again with a valid vote."
    exit 1
fi

VOTE="$VOTE_VALUE:$ISSUE_NUMBER:$TADDR:$(date '+%s')"
echo "Please copy and paste the following (including BEGIN and END lines) into the GitHub issue you referenced above:"

echo ""
echo "-----BEGIN VOTE-----"
echo "$VOTE:$(docker exec -u resuser $(docker ps | grep resistance-core | awk '{print $1}') ./resistance/resistance-cli signmessage $TADDR $VOTE)"
echo "-----END VOTE-----"
echo ""
