#!/usr/bin/env bash

# =============================================================================
# Spring Boot Performance Demo Script
# Compares JPA vs GemFire performance for data loading and querying
# =============================================================================

set -eo pipefail  # Exit on error, pipe failures (unbound vars disabled for SDKMAN compatibility)

# =============================================================================
# CONFIGURATION
# =============================================================================

DEMO_START=$(date +%s)
JAVA25_VERSION="25-librca"

# Metrics URLs for performance comparison
METRICS_URLS=(
    "http://localhost:8080/actuator/metrics/http.server.requests?tag=uri:/load-jpa"
    "http://localhost:8080/actuator/metrics/http.server.requests?tag=uri:/load-gemfire"
    "http://localhost:8080/actuator/metrics/http.server.requests?tag=uri:/get-jpa-count"
    "http://localhost:8080/actuator/metrics/http.server.requests?tag=uri:/get-gemfire-count"
)

METRICS_LABELS=(
    "JPA Data Loading"
    "GemFire Data Loading"
    "JPA Query Count"
    "GemFire Query Count"
)

# Chart display configuration
CHART_COLORS=("█" "▓" "▒" "░")
CHART_WIDTH=40

# Color codes for output
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
WHITE='\033[1;37m'
CYAN='\033[1;36m'
NC='\033[0m'

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

display_header() {
    echo -e "\n${WHITE}#### $1${NC}"
    echo ""
}

pause_and_clear() {
    if [[ "$PROMPT_TIMEOUT" == "0" ]]; then
        read -rs
    else
        read -rst "$PROMPT_TIMEOUT" || true
    fi
    clear
}

# =============================================================================
# DEPENDENCY MANAGEMENT
# =============================================================================

check_command_exists() {
    local cmd="$1"
    local install_msg="$2"

    if ! command -v "$cmd" &> /dev/null; then
        log_error "$cmd not found. $install_msg"
        return 1
    fi
    return 0
}

verify_dependencies() {
    log_info "Checking dependencies..."

    local -a missing_deps=()
    local -a required_commands=(
        "vendir:Please install vendir first"
        "http:Please install httpie first"
        "bc:Please install bc first"
        "git:Please install git first"
        "jq:Please install jq first"
    )

    for cmd_info in "${required_commands[@]}"; do
        local cmd="${cmd_info%%:*}"
        local msg="${cmd_info#*:}"

        check_command_exists "$cmd" "$msg" || missing_deps+=("$cmd")
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        exit 1
    fi

    log_success "All dependencies found"
}

# =============================================================================
# JAVA & SDKMAN MANAGEMENT
# =============================================================================

initialize_sdkman() {
    local sdkman_init="${SDKMAN_DIR:-$HOME/.sdkman}/bin/sdkman-init.sh"

    if [[ ! -f "$sdkman_init" ]]; then
        log_error "SDKMAN not found. Please install SDKMAN first."
        exit 1
    fi

    # Disable strict mode for SDKMAN operations
    set +eu
    # shellcheck disable=SC1090
    source "$sdkman_init"

    log_info "Updating SDKMAN..."
    sdk update
    # Re-enable strict mode
    set -e
}

install_java_if_needed() {
    # Disable strict mode for SDKMAN operations
    set +eu

    if ! sdk list java | grep -q "$JAVA25_VERSION.*installed"; then
        log_info "Installing Java $JAVA25_VERSION..."
        sdk install java "$JAVA25_VERSION"
    else
        log_success "Java $JAVA25_VERSION already installed"
    fi

    # Re-enable strict mode
    set -e
}

setup_java_environment() {
    display_header "Setting up Java 25 environment"

    # Disable strict mode for SDKMAN operations
    set +eu
    pei "sdk use java $JAVA25_VERSION"
    set -e

    pei "java -version"
}

# =============================================================================
# PROCESS MANAGEMENT
# =============================================================================

cleanup_java_processes() {
    local java_pids
    java_pids=$(pgrep java || true)

    if [[ -n "$java_pids" ]]; then
        display_header "Stopping existing Java processes"

        while [[ -n "$java_pids" ]]; do
            log_info "Terminating Java processes: $java_pids"
            pei "kill -9 $java_pids"
            java_pids=$(pgrep java || true)
        done
    fi
}

# =============================================================================
# DOCKER MANAGEMENT
# =============================================================================

start_docker_services() {
    log_info "Starting Docker services..."
    if ! docker compose up -d --remove-orphans; then
        log_error "Failed to start Docker services"
        return 1
    fi

    log_success "All Docker services are ready"
}

stop_docker_services() {
    log_info "Stopping Docker services..."
    docker compose down --quiet > /dev/null 2>&1
}

initialize_environment() {
    docker compose down --quiet > /dev/null 2>&1 || true
    clear
}

# =============================================================================
# SPRING BOOT MANAGEMENT
# =============================================================================

start_spring_boot() {
    display_header "Starting Spring Boot application..."
    pei "./mvnw -q clean package spring-boot:start -Dfork=true -DskipTests 2>&1"
}

stop_spring_boot() {
    display_header "Stopping Spring Boot application"
    ./mvnw --quiet spring-boot:stop -Dspring-boot.stop.fork -Dfork=true > /dev/null 2>&1
}

# =============================================================================
# DEMO OPERATIONS
# =============================================================================

run_jpa_data_load() {
    display_header "Loading data via Spring Data JPA to Postgres"
    pei "time http :8080/load-jpa"
}

run_jpa_count_query() {
    display_header "Querying record count from Postgres via JPA"
    pei "time http :8080/get-jpa-count"
}

run_gemfire_data_load() {
    display_header "Loading data via Spring for GemFire"
    pei "time http :8080/load-gemfire"
}

run_gemfire_count_query() {
    display_header "Querying record count from GemFire"
    pei "time http :8080/get-gemfire-count"
}

# =============================================================================
# METRICS COLLECTION AND ANALYSIS
# =============================================================================

extract_total_time_from_metrics() {
    local url="$1"

    local response
    if ! response=$(http --json --print=b GET "$url" 2>/dev/null); then
        echo "0"
        return
    fi

    if [[ -z "$response" ]]; then
        echo "0"
        return
    fi

    local total_time
    total_time=$(echo "$response" | jq -r '
        if type == "object" and has("measurements") then
            .measurements[] |
            select(.statistic == "TOTAL_TIME") |
            .value
        else
            empty
        end
    ' 2>/dev/null)

    if [[ "$total_time" == "null" || -z "$total_time" ]]; then
        echo "0"
    else
        echo "$total_time"
    fi
}

format_value_for_display() {
    local value="$1"

    if (( $(echo "$value >= 10" | bc -l) )); then
        printf "%.3f" "$value"
    elif (( $(echo "$value >= 1" | bc -l) )); then
        printf "%.4f" "$value"
    elif (( $(echo "$value >= 0.001" | bc -l) )); then
        printf "%.6f" "$value"
    else
        printf "%.9f" "$value"
    fi
}

calculate_percentage_change() {
    local baseline="$1"
    local comparison="$2"

    if (( $(echo "$baseline > 0" | bc -l) )); then
        echo "scale=2; (($comparison - $baseline) / $baseline) * 100" | bc -l
    else
        echo "0"
    fi
}

create_performance_bar() {
    local value="$1"
    local max_value="$2"
    local color="$3"

    local bar_width=0
    if (( $(echo "$max_value > 0" | bc -l) )); then
        bar_width=$(echo "scale=0; ($value / $max_value) * $CHART_WIDTH" | bc -l)
        # Ensure minimum width of 1 for non-zero values
        if (( $(echo "$value > 0 && $bar_width < 1" | bc -l) )); then
            bar_width=1
        fi
    fi

    local bar=""
    for ((i=0; i<bar_width; i++)); do
        bar+="$color"
    done

    echo "$bar"
}

display_comparison_chart() {
    local title="$1"
    local label1="$2"
    local value1="$3"
    local label2="$4"
    local value2="$5"
    local color1="$6"
    local color2="$7"

    # Determine max value for scaling
    local max_value="$value1"
    if (( $(echo "$value2 > $max_value" | bc -l) )); then
        max_value="$value2"
    fi

    echo -e "\n${WHITE}$title${NC}"
    echo "========================================"
    printf "Max value: %.6fs\n" "$max_value"
    echo ""

    # Display first bar
    local bar1
    bar1=$(create_performance_bar "$value1" "$max_value" "$color1")
    local display_value1
    display_value1=$(format_value_for_display "$value1")
    printf "%-20s │ %-42s %ss\n" "$label1" "$bar1" "$display_value1"

    # Display second bar
    local bar2
    bar2=$(create_performance_bar "$value2" "$max_value" "$color2")
    local display_value2
    display_value2=$(format_value_for_display "$value2")
    printf "%-20s │ %-42s %ss\n" "$label2" "$bar2" "$display_value2"

    # Calculate and display percentage change
    local percentage_change
    percentage_change=$(calculate_percentage_change "$value1" "$value2")

    local change_color="$GREEN"
    local change_text="faster"

    if (( $(echo "$percentage_change > 0" | bc -l) )); then
        change_color="$RED"
        change_text="slower"
    else
        # Make percentage positive for display (negative means faster/better)
        percentage_change=$(echo "$percentage_change * -1" | bc -l)
    fi

    echo ""
    printf "Performance Change: "
    printf "${change_color}%.2f%% %s${NC}" "$percentage_change" "$change_text"
    printf " (%s vs %s)\n" "$label1" "$label2"
    echo ""
}

collect_and_display_metrics() {
    display_header "Collecting performance metrics..."

    local -a total_times=()

    # Collect metrics from all URLs
    for i in "${!METRICS_URLS[@]}"; do
        local url="${METRICS_URLS[$i]}"
        local label="${METRICS_LABELS[$i]}"

        echo -n "[$label] "
        local total_time
        total_time=$(extract_total_time_from_metrics "$url")
        total_times+=("$total_time")
        echo "TOTAL_TIME: ${total_time}s"
    done

    echo ""

    # Create comparison charts
    display_comparison_chart \
        "Data Loading Performance: JPA vs GemFire" \
        "${METRICS_LABELS[0]}" "${total_times[0]}" \
        "${METRICS_LABELS[1]}" "${total_times[1]}" \
        "${CHART_COLORS[0]}" "${CHART_COLORS[1]}"

    display_comparison_chart \
        "Query Performance: JPA vs GemFire" \
        "${METRICS_LABELS[2]}" "${total_times[2]}" \
        "${METRICS_LABELS[3]}" "${total_times[3]}" \
        "${CHART_COLORS[2]}" "${CHART_COLORS[3]}"
}



# =============================================================================
# DEMO MAGIC SETUP
# =============================================================================

setup_demo_magic() {
    vendir sync

    # shellcheck disable=SC1091
    source ./vendir/demo-magic/demo-magic.sh

    # Override demo-magic defaults AFTER sourcing
    TYPE_SPEED=100
    PROMPT_TIMEOUT=5
    DEMO_PROMPT="${GREEN}➜ ${CYAN}\W ${NC}"
}

# =============================================================================
# MAIN EXECUTION FLOW
# =============================================================================

main() {
    log_info "Starting Spring Boot Performance Demo"

    # Setup and verification
    verify_dependencies
    setup_demo_magic
    cleanup_java_processes
    initialize_sdkman
    install_java_if_needed

    # Environment preparation
    initialize_environment
    if ! start_docker_services; then
        log_error "Failed to start Docker services. Exiting."
        exit 1
    fi
    pause_and_clear

    # Java setup
    setup_java_environment
    pause_and_clear

    # Application lifecycle
    start_spring_boot
    pause_and_clear

    # Performance testing
    run_jpa_data_load
    pause_and_clear

    run_jpa_count_query
    pause_and_clear

    run_gemfire_data_load
    pause_and_clear

    run_gemfire_count_query
    pause_and_clear

    # Results analysis
    collect_and_display_metrics

    # Cleanup
    stop_spring_boot
    stop_docker_services

    log_success "Demo completed successfully!"
}

# =============================================================================
# SCRIPT ENTRY POINT
# =============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi