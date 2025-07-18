#!/bin/bash
set -euo pipefail

echo "Checking required tools..."

# Check for required tools
tools=("bbrf" "subfinder" "assetfinder" "httpx" "jq")
# Optional fuzzing tools
fuzzing_tools=("gobuster" "ffuf" "dirb")
missing_tools=()
missing_fuzzing_tools=()

for tool in "${tools[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        missing_tools+=("$tool")
    else
        echo "✓ $tool found"
    fi
done

# Check for fuzzing tools
for tool in "${fuzzing_tools[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        missing_fuzzing_tools+=("$tool")
    else
        echo "✓ $tool found"
    fi
done

if [ ${#missing_tools[@]} -ne 0 ]; then
    echo "❌ Missing required tools: ${missing_tools[*]}"
    echo "Please install the missing tools before running the pipeline."
    exit 1
else
    echo "✅ All required tools are available"
fi

if [ ${#missing_fuzzing_tools[@]} -ne 0 ]; then
    echo "⚠️  Missing optional fuzzing tools: ${missing_fuzzing_tools[*]}"
    echo "Install these tools to enable fuzzing capabilities (fuzz.nf)"
else
    echo "✅ All fuzzing tools are available"
fi