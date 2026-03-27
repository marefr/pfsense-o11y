#!/bin/sh

# Get the current state from Tailscale
CURRENT_STATE=$(/usr/local/bin/tailscale status --self --peers=false --json 2>/dev/null | /usr/local/bin/jq -r '.BackendState')

# Evaluate the state: map it exactly, or default to "Unknown"
case "$CURRENT_STATE" in
    Running|NeedsLogin|Stopped|NoState|LoadingConfig)
        MAPPED_STATE="$CURRENT_STATE"
        ;;
    *)
        MAPPED_STATE="Unknown"
        ;;
esac

# Our strict list of states to report to Prometheus
STATES="Running NeedsLogin Stopped NoState LoadingConfig Unknown"

for S in $STATES; do
    VAL=0
    if [ "$S" = "$MAPPED_STATE" ]; then
        VAL=1
    fi
    echo "tailscale_backend,state_desc=$S state=${VAL}i"
done
