#!/bin/bash
BRANCH=main
FILE=rules.json
EXPIRE=360

function usage {
  echo "Usage: $(basename $0) " 2>&1
  echo 'Remove commits from repository.'
  echo '   -f file     File to check for commit history'
  echo '   -b branch   Branch to check for commit history'
  echo '   -e expire   default Expiration time in seconds'
  echo '   -h          Increase verbosity.'
  exit 1
}

while getopts ":b:f:e:v" arg; do
  case $arg in
    b) 
	    BRANCH=$OPTARG
	    ;;
    f) 
	    FILE=$OPTARG
	    ;;
    e)
      EXPIRE=$OPTARG
      ;;
    h) 
	    usage
      exit 0
	    ;;
    ?) 
	    echo "ERROR: unknown option -${OPTARG}"
      usage
	    exit 1
	    ;;
	
  esac
done

# create empty reverted commits
reverted_commits=()

now=$(date -d "now" +%s)

# loop through all commits of test.json on master branch
for commit in $(git rev-list --all ${BRANCH} -- ${FILE})
do

  # ignore commits containing reverted message
  commitrevert=$(git show -s ${commit} | egrep "^    This reverts commit [0-9a-f]{40}\." | sed -E 's|.*([0-9a-f]{40}).*|\1|')
  if [ "${commitrevert}" != "" ]; then
    reverted_commits+=(${commitrevert})
    continue
  fi

  # ignore commits that have been reverted
  if [[ "${reverted_commits[*]}" =~ (^|[^[:alpha:]])$commit([^[:alpha:]]|$) ]]; then
    continue
  fi

  #check expiration
  commitdate=$(git show --date=iso8601 -s ${commit} | egrep "^Date: " | sed -E 's|^Date: +(.+)|\1|' )



  commitdateepoch=$(date -d "$commitdate" +%s)
  let timediff=${now}-${commitdateepoch}



  if [ ${timediff} -gt ${EXPIRE} ]; then
    echo "expired $commit"
    #git revert ${commit}
    continue
  fi
done