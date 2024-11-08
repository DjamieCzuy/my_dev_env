#!/bin/bash
# dev_functions
#
# wait_for_container_to_be_healthy(container_name)
#

wait_for_container_to_be_healthy() {
    container_name=$1
    echo "⏳ Waiting for container: ${container_name} to be 🏃‍♂️ Running and 💪🏾 Healthy"

    last_status=""
    last_health=""
    while true; do
        status=$(docker inspect --format '{{.State.Status}}' "$container_name")
        health=$(docker inspect --format='{{.State.Health.Status}}' $container_name)

        if [ "$status" = "$last_status" ] && [ "$health" = "$last_health" ]; then
            echo -n "."
        else
            echo ""
            echo -n $(date +"%I:%M:%S %p")
            echo -n " > Status: $status ($health) "
            last_status=$status
            last_health=$health
        fi

        if [ "$status" = "running" ] && [ "$health" = "healthy" ]; then
            echo "🏃‍♂️ ➕ 💪🏾"
            break
        fi

        sleep 5
    done
}
