#!/bin/bash

#USAGE: cat list_of_votes.txt | grep -v "BEGIN VOTE" | grep -v "END VOTE" | ./verify.sh GITHUB_ISSUE_NUMBER

#Make sure jq is installed
checkjq() {
    if hash jq 2>/dev/null; then
        echo "jq installed... proceeding"
    else
        sudo apt install jq
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
cd ~

EXPECTED_ISSUE_NUMBER=$1

yes=0
no=0

voted_addr=()

while read VOTE
do
    #echo $VOTE
    VOTE_VALUE=$(echo $VOTE | cut -d":" -f1)
    ISSUE_NUMBER=$(echo $VOTE | cut -d":" -f2)
    TADDR=$(echo $VOTE | cut -d":" -f3)
    TIMESTAMP=$(echo $VOTE | cut -d":" -f4)
    SIGNATURE=$(echo $VOTE | cut -d":" -f5)
    MESSAGE="$VOTE_VALUE:$ISSUE_NUMBER:$TADDR:$TIMESTAMP"

    node_alive=$(curl -s https://resnode.resistance.io/api/nodes | jq -r '.[] | select(.taddr=='\"$TADDR\"') | .hashed_uuid')
    if [ -z "$node_alive" ]
    then
      echo ""
      echo "INVALID! : Node used for Signing is Not Live. Vote Rejected: $VOTE"
      echo ""
      continue
    fi

    if [[ "$EXPECTED_ISSUE_NUMBER" != "$ISSUE_NUMBER" ]]
    then
    	echo ""
    	echo "INVALID! : Github Issue Number Not Correct. Vote Rejected: $VOTE"
    	echo ""
    	continue
    fi

    #docker exec -it -u resuser $(docker ps | grep resistance-core | awk '{print $1}') ./resistance/resistance-cli verifymessage "$TADDR" "$SIGNATURE" "$MESSAGE"

    verify=$(docker exec -u resuser $(docker ps | grep resistance-core | awk '{print $1}') ./resistance/resistance-cli verifymessage "$TADDR" "$SIGNATURE" "$MESSAGE")

    if [[ "$verify" != "true" ]]
    then
    	echo ""
    	echo "INVALID! : Invalid Message Signature. Vote Rejected: $VOTE"
    	echo ""
    	continue
    fi


    #at this point we have concluded that this is a valid vote and we count it

    if [[ " ${voted_addr[@]} " =~ " ${TADDR} " ]]; then
        echo ""
        echo "INVALID! : This Masternode already voted. Vote Rejected: $VOTE"
        echo ""
        continue
    fi

    #at this point we have concluded that this is a valid vote and we count it

    if [[ "$VOTE_VALUE" == "N" ]]
    then
        no=$((no+1))
    fi

    if [[ "$VOTE_VALUE" == "Y" ]]
    then
        yes=$((yes+1))
    fi

    voted_addr+=$TADDR
done

echo ""
echo "--------------------------------------------------------"
echo "| Final Tally for GitHub Issue: $EXPECTED_ISSUE_NUMBER "
echo "--------------------------------------------------------"
echo "| YES: $yes                                            "
echo "|-------------------------------------------------------"
echo "| NO: $no                                             "
echo "--------------------------------------------------------"
