#!/bin/bash

# =============================================================================
# HELPER ACTIONS
# =============================================================================

NC=$(echo "\033[m")
BOLD=$(echo "\033[1;39m")
CMD=$(echo "\033[1;34m")
OPT=$(echo "\033[0;34m")

ENVAR="MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=secret
MONGO_INITDB_LOCATION=temp/db"

action_usage(){
    echo -e "    ____                ______                   "
    echo -e "   / __ \\___  ___  ____/_  __/________  ________ "
    echo -e "  / / / / _ \\/ _ \\/ __ \\/ / / ___/ __ '/ ___/ _ \\"
    echo -e " / /_/ /  __/  __/ /_/ / / / /  / /_/ / /__/  __/"
    echo -e "/_____/\\___/\\___/ .___/_/ /_/   \\__,_/\\___/\\___/ "
    echo -e "IDENTITY       /_/   Developed by Auromind Ltd."
    echo -e ""                                          
    echo -e "${BOLD}System Commands:${NC}"
    echo -e "   ${CMD}init${OPT} ...${NC} initializers environment;"
    echo -e "      ${OPT}-u <USERNAME> ${NC}set MongoDB root user name;"
    echo -e "      ${OPT}-p <PASSWORD>${NC}set MongoDB root password;"
    echo -e "      ${OPT}-l <DIR>${NC}set MongoDB files location;"
    echo -e "   ${CMD}test${OPT} ...${NC} runs tests;"
    echo -e "      ${OPT}-m <MARK> ${NC}runs tests for mark;"
    echo -e "      ${OPT}-c ${NC}generates code coverage summary;"
    echo -e "      ${OPT}-r ${NC}generates code coverage report;"  
}

action_init(){
    # Setup project environment variables
    if [ ! -f .envar ]; then
        while [[ $# -gt 0 ]]; do
            key="$1"
            case $key in
                -u|--username)
                    MONGO_INITDB_ROOT_USERNAME="$2"
                    shift # past argument
                    shift # past value
                ;;
                -p|--password)
                    MONGO_INITDB_ROOT_PASSWORD="$2"
                    shift # past argument
                    shift # past value
                ;;
                -l|--location)
                    MONGO_INITDB_LOCATION="$2"
                    shift # past argument
                    shift # past value
                ;;
                *) # unknown option
                    echo -e "Invalid option!"
                    echo  -e "Usage: init [-u USERNAME] [-p PASSWORD] [-l DIR]"
                    echo -e "Learn more with: ./helper.sh help"
                    exit
                ;;
            esac
        done

        if [ -z "$MONGO_INITDB_ROOT_USERNAME" -a "$MONGO_INITDB_ROOT_USERNAME" = "" ]; then 
            MONGO_INITDB_ROOT_USERNAME='admin'
        fi
        if [ -z "$MONGO_INITDB_ROOT_PASSWORD" -a "$MONGO_INITDB_ROOT_PASSWORD" = "" ]; then 
            MONGO_INITDB_ROOT_PASSWORD='secret'
        fi
        if [ -z "$MONGO_INITDB_LOCATION" -a "$MONGO_INITDB_LOCATION" = "" ]; then 
            MONGO_INITDB_LOCATION='temp/db'
        fi

        echo ".envar file not found and will be created!"
        echo "# The project environment variables" > .envar
        echo "MONGO_INITDB_ROOT_USERNAME=$MONGO_INITDB_ROOT_USERNAME" >> .envar
        echo "MONGO_INITDB_ROOT_PASSWORD=$MONGO_INITDB_ROOT_PASSWORD" >> .envar 
        echo "MONGO_INITDB_LOCATION=$MONGO_INITDB_LOCATION" >> .envar
    fi

    # Setup Python virtual environment 
    if [ -d .venv ];
        then
            rm -r .venv
    fi

    python3 -m venv .venv
    source .venv/bin/activate
    pip3 install -r requirements.txt --no-cache
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
    source .envar

    CONTAINER_ID=$(docker ps -q --filter="NAME=mongo")

    case $1 in
        run)
            sudo docker run -d --name mongo \
                -p 27017:27017 \
                -v $MONGO_INITDB_LOCATION:/data/db \
                -e MONGO_INITDB_ROOT_USERNAME=$MONGO_INITDB_ROOT_USERNAME \
                -e MONGO_INITDB_ROOT_PASSWORD=$MONGO_INITDB_ROOT_PASSWORD \
                mongo
        ;;
        status)
            if [ -z "$CONTAINER_ID" -a "$CONTAINER_ID" = "" ]; then 
                echo -e "MongoDB is not running..."
            else
                echo -e "MongoDB is running ($CONTAINER_ID)..."
            fi 
        ;;
        start)
            if [ -z "$CONTAINER_ID" -a "$CONTAINER_ID" = "" ]; then 
                sudo docker start mongo
            else
                echo -e "MongoDB is running ($CONTAINER_ID)..."
            fi 
        ;;
        stop)
            if [ -z "$CONTAINER_ID" -a "$CONTAINER_ID" = "" ]; then 
                echo -e "MongoDB is not running..."
            else
                sudo docker stop $CONTAINER_ID
            fi 
        ;;
        restart)
            if [ -z "$CONTAINER_ID" -a "$CONTAINER_ID" = "" ]; then 
                sudo docker start mongo
            else
                sudo docker stop $CONTAINER_ID
                sleep 1s
                sudo docker start mongo
            fi 
        ;;
        *)
            echo -e "Invalid command!"
            echo  -e "Usage: mongo [run|status|start|stop|restart]"
            echo -e "Learn more with: ./helper.sh help"
            exit
        ;;
    esac  
}

# =============================================================================
# HELPER COMMANDS SELECTOR
# =============================================================================
case $1 in
    init)
        action_init ${@:2}
    ;;
    test)
        action_test ${@:2}
    ;;
    run)
        action_run
    ;;
    mongo)
        action_mongo ${@:2}
    ;;

    *)
        action_usage
    ;;
esac  

exit 0