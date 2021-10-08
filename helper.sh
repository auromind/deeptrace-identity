#!/bin/bash

# =============================================================================
# HELPER ACTIONS
# =============================================================================

NC=$(echo "\033[m")
BOLD=$(echo "\033[1;39m")
CMD=$(echo "\033[1;34m")
OPT=$(echo "\033[0;34m")

action_usage(){

    echo -e "    ____                ______                   "
    echo -e "   / __ \\___  ___  ____/_  __/________  ________ "
    echo -e "  / / / / _ \\/ _ \\/ __ \\/ / / ___/ __ '/ ___/ _ \\"
    echo -e " / /_/ /  __/  __/ /_/ / / / /  / /_/ / /__/  __/"
    echo -e "/_____/\\___/\\___/ .___/_/ /_/   \\__,_/\\___/\\___/ "
    echo -e "IDENTITY       /_/   Developed by Auromind Ltd."
    echo -e ""                                          
    echo -e "${BOLD}System Commands:${NC}"
    echo -e "   ${CMD}init${NC} initializers environment;"
    echo -e "   ${CMD}test${OPT} ...${NC} runs tests;"
    echo -e "      ${OPT}-m <MARK> ${NC}runs tests for mark;"
    echo -e "      ${OPT}-c ${NC}generates code coverage summary;"
    echo -e "      ${OPT}-r ${NC}generates code coverage report;"  
}

action_init(){
    # if [ -d .venv ];
    #     then
    #         rm -r .venv
    # fi

    # python3 -m venv .venv
    source .venv/bin/activate
    # pip3 install -r requirements.txt --no-cache
    pip3 install python-multipart
}

action_test(){
    source .venv/bin/activate

    OPTS=()
    while getopts ":m:cr" opt; do
        case $opt in
            m)
                OPTS+=(-m $OPTARG) 
                ;;
            c)
                OPTS+=(--cov=bootwrap) 
                ;;
            r)
                OPTS+=(--cov-report=xml:cov.xml) 
                ;;
            \?)
                echo -e "Invalid option: -$OPTARG"
                exit
                ;;
        esac
    done
    
    pytest --capture=no -p no:warnings ${OPTS[@]}
}

action_run(){
    source .venv/bin/activate
    uvicorn main:app --reload
}

action_mongo(){
    sudo docker start $(docker ps -a -q --filter "status=exited")
    # sudo docker run -d --name mongo \
    #     -p 27017:27017 \
    #     -v /media/mykola/Work/workspace/deeptrace/db:/data/db \
    #     -e MONGO_INITDB_ROOT_USERNAME=admin \
    #     -e MONGO_INITDB_ROOT_PASSWORD=secret \
    #     mongo
}

# =============================================================================
# HELPER COMMANDS SELECTOR
# =============================================================================
case $1 in
    init)
        action_init
    ;;
    test)
        action_test ${@:2}
    ;;
    run)
        action_run
    ;;
    mongo)
        action_mongo
    ;;

    *)
        action_usage
    ;;
esac  

exit 0