#!/usr/bin/env bash

DEMO_START=$(date +%s)

# Java version configuration
JAVA25_VERSION="25-librca"

# Function to check if a command exists
check_dependency() {
  local cmd=$1
  local install_msg=$2
  
  if ! command -v "$cmd" &> /dev/null; then
    echo "$cmd not found. $install_msg"
    return 1
  fi
  return 0
}

# Check all required dependencies
check_dependencies() {
  local missing_deps=()
  
  # Check dependencies in parallel by storing results
  check_dependency "vendir" "Please install vendir first." || missing_deps+=("vendir")
  check_dependency "http" "Please install httpie first." || missing_deps+=("httpie")
  check_dependency "bc" "Please install bc first." || missing_deps+=("bc")
  check_dependency "git" "Please install git first." || missing_deps+=("git")
  
  if [ ${#missing_deps[@]} -gt 0 ]; then
    echo "Missing dependencies: ${missing_deps[*]}"
    exit 1
  fi
  
  echo "All dependencies found."
}

# Load helper functions and set initial variables
check_dependencies

vendir sync
. ./vendir/demo-magic/demo-magic.sh
export TYPE_SPEED=100
export DEMO_PROMPT="${GREEN}➜ ${CYAN}\W ${COLOR_RESET}"
export PROMPT_TIMEOUT=5

declare -a URLS=(
    "http://localhost:8080/actuator/metrics/http.server.requests?tag=uri:/load-jpa"
    "http://localhost:8080/actuator/metrics/http.server.requests?tag=uri:/load-gemfire"
    "http://localhost:8080/actuator/metrics/http.server.requests?tag=uri:/get-jpa-count"
    "http://localhost:8080/actuator/metrics/http.server.requests?tag=uri:/get-gemfire-count"
)

# URL labels for the chart (customize as needed)
declare -a LABELS=(
    "load-jpa"
    "load-gemfire"
    "get-jpa-count"
    "get-gemfire-count"
)

# Colors for the chart
declare -a COLORS=(
    "█" "▓" "▒" "░"
)

# Function to extract TOTAL_TIME from micrometer metrics
function extract_total_time() {
   local url=$1
   echo "Fetching metrics from: $url" >&2

   # Use httpie to get JSON only (no headers) and handle any parsing issues
   local response=$(http --json --print=b GET "$url" 2>/dev/null)

   if [ $? -ne 0 ] || [ -z "$response" ]; then
       echo "Error: Failed to fetch from $url" >&2
       echo "0"
       return
   fi

   # Debug: show first few characters of response
   echo "Response preview: $(echo "$response" | head -c 50)..." >&2

   # Extract TOTAL_TIME with better error handling
   local total_time=$(echo "$response" | jq -r '
       if type == "object" and has("measurements") then
           .measurements[] |
           select(.statistic == "TOTAL_TIME") |
           .value
       else
           empty
       end
   ' 2>/dev/null)

   if [ "$total_time" == "null" ] || [ -z "$total_time" ] || [ "$total_time" == "" ]; then
       echo "Warning: TOTAL_TIME not found in response from $url" >&2
       echo "0"
   else
       echo "$total_time"
   fi
}

# Function to create a simple ASCII bar chart with better precision
create_chart() {
    local -a values=("$@")
    local max_value=0
    local max_width=40

    # Find the maximum value for scaling
    for value in "${values[@]}"; do
        if (( $(echo "$value > $max_value" | bc -l) )); then
            max_value=$value
        fi
    done

    echo "Spring Micrometer TOTAL_TIME Comparison"
    echo "========================================"
    printf "Max value: %.6fs\n" "$max_value"
    echo ""

    # Create bars
    for i in "${!values[@]}"; do
        local value=${values[$i]}
        local label=${LABELS[$i]}
        local color=${COLORS[$i]}

        # Calculate bar width (avoid division by zero)
        local bar_width=0
        if (( $(echo "$max_value > 0" | bc -l) )); then
            bar_width=$(echo "scale=0; ($value / $max_value) * $max_width" | bc -l)
            # Ensure minimum width of 1 for non-zero values
            if (( $(echo "$value > 0 && $bar_width < 1" | bc -l) )); then
                bar_width=1
            fi
        fi

        # Create the bar
        local bar=""
        for ((j=0; j<bar_width; j++)); do
            bar+="$color"
        done

        # Format display with appropriate precision based on value magnitude
        local display_value
        if (( $(echo "$value >= 10" | bc -l) )); then
            display_value=$(printf "%.3f" "$value")
        elif (( $(echo "$value >= 1" | bc -l) )); then
            display_value=$(printf "%.4f" "$value")
        elif (( $(echo "$value >= 0.001" | bc -l) )); then
            display_value=$(printf "%.6f" "$value")
        else
            display_value=$(printf "%.9f" "$value")
        fi

        printf "%-20s │ %-42s %ss\n" "$label" "$bar" "$display_value"
    done
    echo ""
}

# Stop ANY & ALL Java Process...they could be Springboot running on our ports!
function cleanUp {
	local npid=""

  npid=$(pgrep java)
  
 	if [ "$npid" != "" ] 
		then
  		
  		displayMessage "*** Stopping Any Previous Existing SpringBoot Apps..."		
			
			while [ "$npid" != "" ]
			do
				echo "***KILLING OFF The Following: $npid..."
		  	pei "kill -9 $npid"
				npid=$(pgrep java)
			done  
		
	fi
}

# Function to pause and clear the screen
function talkingPoint() {
  wait
  clear
}

# Check if Java version is already installed
check_java_installed() {
  local version=$1
  sdk list java | grep -q "$version" && sdk list java | grep "$version" | grep -q "installed"
}

# Initialize SDKMAN and install required Java versions
function initSDKman() {
  local sdkman_init
  sdkman_init="${SDKMAN_DIR:-$HOME/.sdkman}/bin/sdkman-init.sh"
  if [[ -f "$sdkman_init" ]]; then
    # shellcheck disable=SC1090
    source "$sdkman_init"
  else
    echo "SDKMAN not found. Please install SDKMAN first."
    exit 1
  fi
  
  echo "Updating SDKMAN..."
  sdk update
  
  if ! check_java_installed "$JAVA25_VERSION"; then
    echo "Installing Java $JAVA25_VERSION..."
    sdk install java "$JAVA25_VERSION"
  else
    echo "Java $JAVA25_VERSION already installed."
  fi
}

# Prepare the working directory
function init {
  docker compose down
  clear
}

function dockerComposeUp {
  docker compose up -d --remove-orphans
}

function dockerComposeDown {
  docker compose down --quiet > /dev/null 2>&1
}

# Switch to Java 25 and display version
function useJava25 {
  displayMessage "Using Java 25 because its awesome!"
  pei "sdk use java $JAVA25_VERSION"
  pei "java -version"
}

# Start the Spring Boot application
function springBootStart {
  displayMessage "Start the Spring Boot application, Wait For It...."
  pei "./mvnw -q clean package spring-boot:start -Dfork=true -DskipTests 2>&1"
}

# Stop the Spring Boot application
function springBootStop {
  displayMessage "Stop the Spring Boot application"
  pei "./mvnw --quiet spring-boot:stop -Dspring-boot.stop.fork -Dfork=true > /dev/null 2>&1"
}

# Display a message with a header
function displayMessage() {
  echo "#### $1"
  echo ""
}

function statsSoFarTableColored {
  displayMessage "Comparison of memory usage and startup times"
  echo ""

  # Define colors
  local WHITE='\033[1;37m'
  local GREEN='\033[1;32m'
  local BLUE='\033[1;34m'
  local NC='\033[0m' # No Color

  # Headers (White)
  printf "${WHITE}%-35s %-25s %-15s %s${NC}\n" "Configuration" "Startup Time (seconds)" "(MB) Used" "(MB) Savings"
  echo -e "${WHITE}--------------------------------------------------------------------------------------------${NC}"

  # Spring Boot 1.5 with Java 8 (Red - baseline)
  MEM1=$(cat java8with1.5.log2)
  START1=$(startupTime 'java8with1.5.log')
  printf "${RED}%-35s %-25s %-15s %s${NC}\n" "Spring Boot 1.5 with Java 8" "$START1" "$MEM1" "-"

  # Spring Boot 3.5 with Java17 (Green - improved)
  MEM2=$(cat java17with3.5.log2)
  PERC2=$(bc <<< "scale=2; 100 - ${MEM2}/${MEM1}*100")
  START2=$(startupTime 'java17with3.5.log')
  PERCSTART2=$(bc <<< "scale=2; 100 - ${START2}/${START1}*100")
  printf "${GREEN}%-35s %-25s %-15s %s ${NC}\n" "Spring Boot 3.5 with Java 17" "$START2 ($PERCSTART2% faster)" "$MEM2" "$PERC2%"

  echo -e "${WHITE}--------------------------------------------------------------------------------------------${NC}"
  DEMO_STOP=$(date +%s)
  DEMO_ELAPSED=$((DEMO_STOP - DEMO_START))
  echo ""
  echo ""
  echo -e "${BLUE}Demo elapsed time: ${DEMO_ELAPSED} seconds${NC}"
}

function loadJPA {
  displayMessage "*** Load all of the data via Spring Data JPA to Postgres...How long will this take?"
  pei "time http :8080/load-jpa"
}

function jpaCount {
  displayMessage "*** Get the number (count) of records from Postgres via JPA"
  pei "time http :8080/get-jpa-count"
}

function loadGemfire {
  displayMessage "*** Load the exact same set of data using Spring for Gemfire...How much faster was that?"
  pei "time http :8080/load-gemfire"
}

function gemfireCount {
  displayMessage "*** Get the number (count) of records from Gemfire...How much faster was that simple query?"
  pei "time http :8080/get-gemfire-count"
}

capture_metrics() {
# Collect metrics from all URLs
    declare -a total_times=()

    for i in "${!URLS[@]}"; do
        local url=${URLS[$i]}
        local label=${LABELS[$i]}

        echo -n "[$label] "
        local total_time=$(extract_total_time "$url")
        total_times+=("$total_time")
        echo "TOTAL_TIME: ${total_time}s"
    done

    echo ""

    # Create comparison chart
    create_chart "${total_times[@]}"
}

# Main execution flow

cleanUp
initSDKman
init
dockerComposeUp
talkingPoint
useJava25
talkingPoint
springBootStart
talkingPoint
loadJPA
talkingPoint
jpaCount
talkingPoint
loadGemfire
talkingPoint
gemfireCount
talkingPoint
capture_metrics
springBootStop
dockerComposeDown