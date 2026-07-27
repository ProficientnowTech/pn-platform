setup() { O="$(cd "$BATS_TEST_DIRNAME/../orchestrator" && pwd)"; }
@test "resume skips completed phases (dry-run)" {
  export STATE_DIR="$BATS_TEST_TMPDIR/st"; mkdir -p "$STATE_DIR"; echo '{"last":3}' > "$STATE_DIR/phase.json"
  run "$O/run.sh" --cluster t --resume --dry-run
  [[ "$output" == *"skip phase 1"* ]]; [[ "$output" == *"start phase 4"* ]]
}
@test "fresh run starts at phase 0 (dry-run)" {
  export STATE_DIR="$BATS_TEST_TMPDIR/st2"
  run "$O/run.sh" --cluster t --dry-run
  [[ "$output" == *"start phase 0"* ]]; [[ "$output" == *"bootstrap complete"* ]]
}
@test "gate blocks without yes, passes with YES=1" {
  run bash -c "source '$O/lib/gate.sh'; echo '' | gate x"; [ "$status" -ne 0 ]
  run bash -c "source '$O/lib/gate.sh'; YES=1 gate x"; [ "$status" -eq 0 ]
}
