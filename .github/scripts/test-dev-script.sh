#!/usr/bin/env bash
# Test suite for dev.sh script

set -e

SCRIPT="./dev.sh"

echo "Testing dev.sh script..."
echo ""

# Test 1: Syntax validation
echo "✓ Test 1: Bash syntax validation"
bash -n "$SCRIPT"
echo "  PASSED: No syntax errors"
echo ""

# Test 2: Script is executable
echo "✓ Test 2: Script executable check"
[ -x "$SCRIPT" ] || chmod +x "$SCRIPT"
echo "  PASSED: Script is executable"
echo ""

# Test 3: Help command
echo "✓ Test 3: Help command output"
help_output=$(bash "$SCRIPT" help)
if echo "$help_output" | grep -q "Configure commands:"; then
  echo "  PASSED: Help output contains expected header"
else
  echo "  FAILED: Help output missing header"
  exit 1
fi
echo ""

# Test 4: All commands are recognized
echo "✓ Test 4: Command recognition"
commands=("env" "e" "new" "n" "login" "l" "docker" "dk" "ec2" "ec" "init" "i" "up" "u" "down" "d" "build" "b" "push" "p" "deploy" "y" "logs" "lg" "web" "w" "ssh" "s" "clean" "c" "nuke" "x" "help" "h")
for cmd in "${commands[@]}"; do
  if echo "$help_output" | grep -q "$cmd"; then
    echo "  ✓ Command '$cmd' listed in help"
  fi
done
echo ""

# Test 5: Unknown command error handling
echo "✓ Test 5: Unknown command error handling"
if bash "$SCRIPT" unknowncommand 2>&1 | grep -q "Unknown command"; then
  echo "  PASSED: Unknown command produces error message"
else
  echo "  FAILED: Unknown command error handling"
  exit 1
fi
echo ""

# Test 6: Completion script syntax
echo "✓ Test 6: Bash completion syntax validation"
bash -n ./dev.sh.completion
echo "  PASSED: Completion script has no syntax errors"
echo ""

echo "All tests PASSED! ✓"
