#!/bin/bash                                    zangsm.sh#
#========================================================
zangsm=$(cat << "EOF" 
       _____   _    _   _  ____ ____  __  __
      |__  /  / \  | \ | |/ ___/ ___||  \/  |
        / /  / _ \ |  \| | |  _\___ \| |\/| |
       / /_ / ___ \| |\  | |_| |___) | |  | |
      /____/_/   \_\_| \_|\____|____/|_|  |_|

EOF
)
#========================================================
# Global Declarations
    NUM_CONFIGS=0
    NUM_BOOTED=0

# Function to display header
function header() {
    echo "#========================================================"
    echo "$zangsm"; echo
    echo "#========================================================"
}
# Function to handle server booting
function boot_server() {
    # Config Check
        if [ -z "$1" ]; then
            echo "ZANGSM: Error no config file parsed. Use [-boot config.cfg config2.cfg ...]"
        return
        fi
    # Declarations
      local CONFIG="$1"
      declare -a SV_PID
      ((NUM_CONFIGS++))
    # Validations                                           
     # Prefix /cfgs/ and source $CONFIG
      if [[ ! $CONFIG == /* ]]; then CONFIG="./cfgs/$CONFIG";
        # Source server config file
        source "$CONFIG" ; echo "ZANGSM: Sourcing $CONFIG"
      else source "$CONFIG" ; echo "ZANGSM: Sourcing $CONFIG" ; fi
      # Check if the config file exists
      if [ ! -f "$CONFIG" ]; then
        echo "Error: Config file $CONFIG not found. Continuing..."
      return ; fi

    # Prefixer                                              
    # Auto add "-file" prefix to each element in the array
    for ((i=0; i<${#PWAD[@]}; i++)); do
    PWAD[$i]="-file '${PWAD[$i]}'" ; done
  
    # Auto add "-optfile" prefix to each element in the array
    for ((i=0; i<${#OWAD[@]}; i++)); do
    OWAD[$i]="-optfile '${OWAD[$i]}'"; done
  
    # Auto add "+addmap" prefix to each element in array
    for ((i=0; i<${#MAPLIST[@]}; i++)); do
    MAPLIST[$i]="+addmap '${MAPLIST[$i]}'"; done
  
    # Add "+masterhostname" prefix to master server variable
    MASTER="+masterhostname $MASTER"
    PORT="-port $PORT"

    # Initialization
    SVNAME=$(echo "$SVHOSTNAME" | grep -o -P "'\K[^']+(?=')")
    SESHNAME=$(basename "$CONFIG" .cfg)
    # Setup server logging
      LOG="logs/${SESHNAME}_$(date +"%Y%m%d%H%M%S")_$$.log"; mkdir -p logs
      echo "ZANGSM: Logging to $LOG"
  
    # Force master and host into zandronum.ini workaround
    # May have to set this to only run when using zan/q-zan
    # So that it doesn't try do this for SRB2/Kart servers
    if [ "$zanver" = "./zandronum-server" ] || [ "$zanver" = "./q-zandronum-server" ]; then
      ZAN_INI="$HOME/.config/zandronum/zandronum.ini"
      sed -i "s/masterhostname=.*/masterhostname=/" "$ZAN_INI"
      #echo "Bashing: "$MASTER to $ZAN_INI""
      sed -i "s/sv_hostname=.*/sv_hostname=$SVNAME/" "$ZAN_INI"
      #echo "Bashing: "$SVNAME to $ZAN_INI""
    fi
    # This corrects bug with q-zandronum-server not setting 
    # hostname correctly and using previous configs hostname
    # For some reason this did not affect zandronum-server

    # Construct the BOOT command line
    #echo "ZANGSM: Constructing boot command line from config..."; echo
    BOOT="$ZANVER $IWAD "${PWAD[@]}" "${OWAD[@]}" $PORT $HOST \
    $MASTER $SVHOSTNAME $MOTD "${SVAR[@]}" "${GVAR[@]}" \
    "${DMVAR[@]}" "${MAPLIST[@]}" "${MAPVAR[@]}" "${ADD_PARMS[@]}""
    #echo "$BOOT"
      # Check if the tmux session already exists
        if tmux has-session -t "$SESHNAME" 2>/dev/null; then
            echo "ZANGSM: Error duplicate '$SESHNAME' session found. Skipped."; echo
            ((NUM_BOOTED--))
            return 1  # Exit the function
        fi
    # Zandronum Server Subshell
    echo "ZANGSM: Starting: $SVNAME"
    (

      # Start server in tmux session and tee stdout to log
        tmux new-session -d -s "$SESHNAME" "$BOOT 2>&1 | tee -a $LOG"
        sleep 1 # Sleep for a moment to allow server start
      # Trap Ctrl+C and call the cleanup function
        trap cleanup INT
      # Get PID of latest process matching zanver
        ZAN_PIDS=$(pgrep -f ".*$ZANVER.*")
      # Sort PIDs to get the latest one
        sort_PIDS=($(echo "${ZAN_PIDS[@]}" | tr ' ' '\n' | sort -n -r))
        ZAN_PID="${sort_PIDS[0]}"
      
      # Wait loop to confirm server running
       echo -n "ZANGSM: Waiting for server to start..."
       case "$ZANVER" in
        "./zandronum-server" | "./q-zandronum-server")
          # Wait for "UDP Initialized."
          until grep -q "UDP Initialized." "$LOG" || ! ps -p "$ZAN_PID" > /dev/null; do
          sleep 1
          echo -n "."
          done
        ;;
        "./lsdl2srb2" | "./lsdl2srb2kart")
          # Wait for "Entering main game loop..."
          until grep -q "Entering main game loop..." "$LOG" || ! ps -p "$ZAN_PID" > /dev/null; do
          sleep 1
          echo -n "."
          done
        ;;
        *)
          echo "ZANGSM: Unsupported server type: $ZANVER"
        ;;
       esac
       echo
       if ps -p "$ZAN_PID" > /dev/null; then
         echo "ZANGSM: Server running. [OK]"
        else
         echo "ZANGSM: Server failed. Check the "$LOG" for details."
       fi
  
      # Get port number from server log
      ip_address=$(grep 'IP address' "$LOG")
      if [ "$ZANVER" = "./zandronum-server" ] || [ "$ZANVER" = "./q-zandronum-server" ]; then
        port_num=$(echo "$ip_address" | awk '{print $NF}' | awk -F: '{print $2}')
      else
        # Set the port directly based on your configuration
        port_num="$PORT"
      fi
      # Get WAN IP and combine into address
      wan_ip=$(curl -s -N -4 ifconfig.co)
      ADDRESS="$wan_ip:$port_num"
      echo "ZANGSM: Network live "$ADDRESS""
   
      # Add new entry to zansrvs
      echo "$CONFIG,$ZAN_PID,$SVNAME,$LOG" >> zansrvs
      sed -i '/^$/d' zansrvs  # Remove empty lines
      #echo "Export: PID $ZAN_PID session to zansrvs"

      # Get memory usage of server 
        SRV_MEM_KB=$(ps -p "$ZAN_PID" -o rss=)
        SRV_MEM_MB=$((SRV_MEM_KB / 1024))
        echo "ZANGSM: Memory committed: [$SRV_MEM_MB] MB"; echo
    ) & SV_PID+=("$!") # Add PID to storage array
    # Increment the counter if the server started successfully
        if [ $? -eq 0 ]; then ((NUM_BOOTED++)); else
            echo "ZANGSM: Error Server failed to start. Check $LOG for details."
            echo "ZANGSM: Continuing..."; fi


    # Wait for server to finish booting before proceeding
      for PID in "${SV_PID[@]}"; do wait "$PID" ; done
    # Clear out variables used in loop for config
      unset ZANVER MASTER PORT HOST IWAD PWAD OWAD SVHOSTNAME MOTD SVAR GVAR DMVAR MAPLIST MAPVAR ADD_PARMS BOOT
}
# Function to end zangsm after booting all configs
function done_booting() {
    if [ "$NUM_BOOTED" -lt 0 ]; then
        NUM_BOOTED=0
    fi
    echo "ZANGSM: Boot finished. Summary..."
    echo " - Parsed: [$NUM_CONFIGS] configs..."
    echo " - Booted: [$NUM_BOOTED] servers. [OK]"
    echo " - Total Memory used: [$TOTAL_MEM] MB"
    echo "ZANGSM: Exiting to terminal..."
    echo "#========================================================"
}
# Function to check server memory usage (use inside <for i in "${!ZAN_SRVS[@]}"; do>)
function server_memory(){
    # Check memory of PID
     if [ -z "$ZAN_PID" ]; then
            continue  # Skip empty lines
        fi
        SRV_MEM_KB=$(ps -p "$ZAN_PID" -o rss= 2>/dev/null)
        if [ -n "$SRV_MEM_KB" ]; then
            SRV_MEM_MB=$((SRV_MEM_KB / 1024))
        fi
}
# Function to calculate total memory usage from zansrvs file
function total_memory() {
    read_zansrvs
    # Calculate memory usage
        TOTAL_MEM=0
        while IFS=, read -r CONFIG ZAN_PID SVNAME LOG; do
           if [ -z "$ZAN_PID" ]; then
              continue  # Skip empty lines
            fi
            SRV_MEM_KB=$(ps -p "$ZAN_PID" -o rss= 2>/dev/null)
            if [ -n "$SRV_MEM_KB" ]; then
               SRV_MEM_MB=$((SRV_MEM_KB / 1024))
                TOTAL_MEM=$((TOTAL_MEM + SRV_MEM_MB))
            fi
        done < <(grep -v '^$' zansrvs)
}
# Function to list active sessions
function list_sessions() {
    echo
    read_zansrvs
    # Indexed session list display
        for i in "${!ZAN_SRVS[@]}"; do
            IFS=',' read -r CONFIG ZAN_PID SVNAME LOG <<< "${ZAN_SRVS[i]}"
            SESHNAME=$(basename "$CONFIG" .cfg)
            echo "Session: $SESHNAME - Server: $SVNAME"
            echo "PID: $ZAN_PID [OK] - Memory Usage: [$SRV_MEM_MB] MB"
            echo "Log: $LOG"; echo
        done
}
# Function to read zansrvs array from file
function read_zansrvs() {
    local calling_function=$1
    exist_zansrvs "$calling_function"|| exit 1
    # Read zansrvs file into an array
        ZAN_SRVS=()
        while IFS= read -r ZAN_SRV; do
        if [[ -n "$ZAN_SRV" ]]; then
            ZAN_SRVS+=("$ZAN_SRV")
        fi
        done < zansrvs
}
# Function to check for zansrvs file
function exist_zansrvs() {
    # Check for presence of zansrvs file
        if [ ! -f "zansrvs" ]; then
          echo "ZANGSM: Error - zansrvs file not found or no servers running."
          echo "ZANGSM: Exiting to terminal..."
          exit 1
        fi
}
# Function to match zansrvs with list-sessions
function check_sessions() {
    # Check active sessions and remove inactive ones from zansrvs
        echo "ZANGSM: Scanning for active sessions..."
        for ZAN_SRV in "${ZAN_SRVS[@]}"; do
        IFS=',' read -r CONFIG ZAN_PID SVNAME LOG <<< "$ZAN_SRV"
        SESHNAME=$(basename "$CONFIG" .cfg)

    # Check if the session exists
     if ! tmux has-session -t "$SESHNAME" 2>/dev/null; then
        # Use awk to filter out the inactive session
        awk -v var="$ZAN_SRV" '$0 != var' zansrvs > zansrvs.tmp && mv zansrvs.tmp zansrvs
        echo "ZANGSM: Removing session mismatch: $SESHNAME"
     fi
     done
}
# Function to list indexed sessions
function index_sessions() {
  # Show indexed list of sessions to choose from
    for i in "${!ZAN_SRVS[@]}"; do
        IFS=',' read -r CONFIG ZAN_PID SVNAME LOG <<< "${ZAN_SRVS[i]}"
        server_memory
        null_servers
        if [ -n "$CONFIG" ]; then
            SESHNAME=$(basename "$CONFIG" .cfg)
            # Display the server information
             echo "[$i] Session: $SESHNAME - "Server: $SVNAME""
             echo  "PID: $ZAN_PID - Memory Usage: [$SRV_MEM_MB] MB"
             echo "Log: $LOG"; echo
        fi
    done
}
# Function to handle no servers running
function null_servers(){

    # If no servers are running
        if [ "${#ZAN_SRVS[@]}" -eq 0 ]; then
            echo
            echo "ZANGSM: No servers found. Exiting to terminal..."
            exit 1
        fi
}
# Function to connect to a session
function connect_session() {
    local session_index="$1"
    exist_zansrvs || exit 1
    read_zansrvs
    echo
    index_sessions
    # Ask the user to select a session to connect
     read -p "ZANGSM: Enter index number of session to connect (or 'q' to quit): " choice
    # Handle if choice is q to quit
        if [[ "$choice" = "q" ]]; then
            echo "ZANGSM: Exiting to terminal..."
            exit 0
        fi
    # Handle all other choices
     if [[ "$choice" != "q" ]]; then
      if [[ ! "$choice" =~ ^[0-9]+$ ]] || ((choice >= ${#ZAN_SRVS[@]})); then
      echo "ZANGSM: Invalid selection. Exiting..."
        else
        IFS=',' read -r CONFIG ZAN_PID SVNAME LOG <<< "${ZAN_SRVS[choice]}"
            if [ -n "$CONFIG" ]; then
                SESHNAME=$(basename "$CONFIG" .cfg)
                # Connect to tmux session
                echo "ZANGSM: Connecting to session: $SESHNAME"
                tmux attach-session -t "$SESHNAME"
            else
                echo "ZANGSM: Invalid session name. Exiting to terminal..."
          fi
       fi
     fi
    # Check if the session still exists
     if tmux has-session -t "$SESHNAME" 2>/dev/null; then
        echo "ZANGSM: Session '$SESHNAME' continuing in background..."
     else
        echo "ZANGSM: Session '$SESHNAME' has been terminated."
        awk -v var="$ZAN_SRV" '$0 != var' zansrvs > zansrvs.tmp && mv zansrvs.tmp zansrvs
     fi
    echo "ZANGSM: Exiting to terminal..."
}
# Function to kill a specific session
function kill_session() {
    local session_index="$1"
    exist_zansrvs || exit 1
    echo
    index_sessions
    # Ask the user to select a session to connect
     read -p "ZANGSM: Enter index number of session to kill (or 'q' to quit): " choice
    # Handle if choice is q to quit
        if [[ "$choice" = "q" ]]; then
            echo "ZANGSM: Exiting to terminal..."
            exit 0
        fi
    # Handle all other choices
     if [[ "$choice" != "q" ]]; then
      if [[ ! "$choice" =~ ^[0-9]+$ ]] || ((choice >= ${#ZAN_SRVS[@]})); then
      echo "ZANGSM: Invalid selection. Exiting..."
        else
        IFS=',' read -r CONFIG ZAN_PID SVNAME LOG <<< "${ZAN_SRVS[choice]}"
        SESHNAME=$(basename "$CONFIG" .cfg)
        if tmux has-session -t "$SESHNAME" 2>/dev/null; then
            # Send a shutdown signal to the tmux session
            tmux send-keys -t "$SESHNAME" C-c
            echo "ZANGSM: Shutdown signal to session: $SESHNAME"
            sleep 1 # Allow time for the server to shut down
            echo "ZANGSM: Session: $SESHNAME shutdown."
        fi
        # Remove the zansrvs file if killing the last server
        if [ "${#ZAN_SRVS[@]}" -eq 1 ]; then
          rm -f zansrvs
          echo "ZANGSM: Removed zansrvs file."
        else
          # Otherwise, use awk to remove the line from zansrvs
          awk -v choice="$choice" 'NR!=choice+1' zansrvs > zansrvs_temp
          mv zansrvs_temp zansrvs
          echo "ZANGSM: Removed $SESHNAME from zansrvs file."
        fi
      fi
     fi
    echo "ZANGSM: Exiting to terminal..."
    exit 0
}
# Function to kill all sessions from zansrvs
function kill_all_sessions() {
    local killed=0
    echo "ZANGSM: Committing GENOCIDE..."; echo
    # Get the list of currently active sessions
        active_sessions=$(tmux list-sessions -F "#{session_name}")

    # Iterate through each session and send the termination signal
     for session_name in $active_sessions; do
        echo "ZANGSM: Ending session: $session_name"
        tmux kill-session -t "$session_name"
        echo "ZANGSM: Session $session_name ended."; echo
        ((killed++))
        sleep 1 # Allow time for the server to shut down
     done
    tmux_failsafe
    # Remove zansrvs file and end function
        rm -f zansrvs
        echo "ZANGSM: Removed zansrvs file"
        echo "ZANGSM: GENOCIDE complete. [$killed] servers killed."
        echo "ZANGSM: Exiting to terminal..."
}
# Function to kill any existing tmux sessions
function tmux_failsafe() {
    echo "ZANGSM: Killing tmux server..."
    # Check if the calling function is "kill_all_sessions"
        if ! command -v tmux &> /dev/null; then
            echo "ZANGSM: Error - tmux not found. Exiting"
            exit 1
        fi

        if tmux list-sessions 2>/dev/null | grep -qE 'windows|created'; then
            echo "ZANGSM: Killing all tmux sessions..."
            tmux kill-server
            echo "ZANGSM: All tmux sessions killed."
        else
            echo "ZANGSM: No tmux sessions found."
        fi
     
}
# Function to handle cleanup on interrupt (Ctrl+C)
function cleanup() {
    echo -e "\rZANGSM: Boot Interrupted. Cleaning up..."
     # Kill the tmux session if it exists
    if tmux has-session -t "$SESHNAME" 2>/dev/null; then
        tmux kill-session -t "$SESHNAME"
        echo -e "\rZANGSM: Aborted current session '$SESHNAME'."
    fi
    sleep 1
    # Add any cleanup commands here
    exit 1
}

# Function to display zangsm options
function show_options(){
    echo "ZANGSM: Options [-boot conf.cfg...] (Boot one or more servers)"
    echo "                [-list]             (List active servers)"
    echo "                [-connect]          (Connect to a server session)"
    echo "                [-kill]             (Kill a specific server)"
    echo "                [-killall]          (Kill all servers)"
}
# Main script
 while [[ $# -gt 0 ]]; do
    case "$1" in
        -boot)
            header
            #check_sessions
            shift
            while [[ $# -gt 0 ]]; do
                boot_server "$1"
                shift
            done
            total_memory
            done_booting
            exit
            ;;
        -list)
            header
            check_sessions
            total_memory
            list_sessions
            ;;
        -connect)
            header
            read_zansrvs
            check_sessions
            shift
            connect_session "$1"
            ;;
        -kill)
            header
            read_zansrvs
            check_sessions
            shift
            kill_session "$1"
            ;;
        -killall)
            header
            kill_all_sessions
            ;;
        *)
            echo "ZANGSM: Unknown option: $1"
            show_options
            ;;
    esac
    shift
 done
# Notes




