#!/bin/bash

function _requeue() {
  local now timespec
  now="$(date '+%s')"
  timespec="$(date --date="@$(((now / JOB_PERIOD + 1) * JOB_PERIOD + JOB_OFFSET))" '+%Y-%m-%dT%H:%M:%S')"

  echo "$(date): requeing job $SLURM_JOB_ID ($SLURM_JOB_NAME) to run at $timespec"

  scontrol requeue "$SLURM_JOB_ID"
  scontrol update JobId="$SLURM_JOB_ID" StartTime="$timespec"
}

function _near_timeout() {
  if [[ -n "$CHILD_PID" ]]; then
    echo "$(date): notifying child $CHILD_PID about timeout"
    kill -SIGUSR1 "$CHILD_PID" || true
    sleep 5
  fi
  _requeue
}

function sane-wait() {
  # https://stackoverflow.com/a/35755784/13649511
  local status=0
  while :; do
    wait "$@" || local status="$?"
    if [[ "$status" -lt 128 ]]; then
      return "$status"
    fi
  done
}

trap '_near_timeout' SIGUSR1          # job needs to specify --signal=B:SIGUSR1@90
trap '_requeue' EXIT HUP INT TERM ERR # handle requeue on other conditions

echo "$(date): job $SLURM_JOB_ID ($SLURM_JOB_NAME) starting on $SLURM_NODELIST"

chaotic routine "$SLURM_JOB_NAME" &
CHILD_PID="$!"

echo "$(date): child running with pid $CHILD_PID"
sane-wait "$CHILD_PID"
