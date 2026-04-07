#!/bin/bash
#
# capture_screenshots.sh
# Captures App Store screenshots by running ScreenshotTests on multiple simulator
# destinations, then extracts and organises the images for App Store upload.
#
# Prerequisites:
#   - Docker must be installed and running (the script handles compose up/down itself).
#   - The WebService/.env file must exist with the required env vars (PGUSER, PGPASSWORD, etc.).
#
# Usage (run from repo root):
#   bash Clients/iOS/scripts/capture_screenshots.sh
#
# Or run from the project directory:
#   cd Clients/iOS/FitWithFriends && ../scripts/capture_screenshots.sh
#
# Output structure:
#   Clients/iOS/FitWithFriends/screenshots/
#     iPhone_6.9/
#       01_WelcomeScreen.png
#       02_HomeScreen.png
#       ...
#     iPad_12.9/
#       ...
#

set -e

# Resolve the project directory regardless of where the script is called from
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/../FitWithFriends"
REPO_ROOT="$SCRIPT_DIR/../../.."
DOCKER_COMPOSE_FILE="$REPO_ROOT/WebService/docker-compose-local-testing.yml"

SCHEME="FitWithFriends"
PROJECT="FitWithFriends.xcodeproj"
TEST_TARGET="FitWithFriends_UITests"
TEST_CLASS="ScreenshotTests"
OUTPUT_DIR="$PROJECT_DIR/screenshots"

# Clean previous results
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

echo "=== Capturing App Store Screenshots ==="
echo ""

# Restart the backend with a clean database so screenshots start from a known state.
# -v removes the postgres volume so the DB is fully re-initialised from the SQL seed scripts.
echo "--- Restarting backend with clean database ---"
docker compose -f "$DOCKER_COMPOSE_FILE" down -v --remove-orphans
docker compose -f "$DOCKER_COMPOSE_FILE" up -d

echo "  Waiting for backend to be ready..."
for i in $(seq 1 60); do
    if curl -sf http://localhost:3000 > /dev/null 2>&1; then
        echo "  Backend is ready."
        break
    fi
    if [ "$i" -eq 60 ]; then
        echo "  ERROR: Backend did not become ready after 60s. Aborting."
        exit 1
    fi
    sleep 1
done
echo ""

# Device configurations for App Store submission.
# App Store requires at least one 6.9" iPhone screenshot and one 13" iPad screenshot.
# iPhone 17 Pro Max  → satisfies the 6.9" required category.
# iPad Pro 13-inch (M5) → satisfies the 13" required category.
# Add more devices below as needed.
declare -a DEVICES=(
    "iPhone 17 Pro Max|iPhone_6.9"
    "iPad Pro 13-inch (M5)|iPad_12.9"
)

for device_config in "${DEVICES[@]}"; do
    IFS='|' read -r device_name folder_name <<< "$device_config"

    RESULT_BUNDLE="$OUTPUT_DIR/${folder_name}_result.xcresult"
    EXPORT_DIR="$OUTPUT_DIR/${folder_name}_raw"
    FINAL_DIR="$OUTPUT_DIR/$folder_name"

    echo "--- Capturing screenshots on: $device_name ---"

    # Clean any pre-existing result bundle (xcodebuild fails if it already exists)
    rm -rf "$RESULT_BUNDLE"

    # Run the screenshot UI tests
    set +e
    xcodebuild test \
        -project "$PROJECT_DIR/$PROJECT" \
        -scheme "$SCHEME" \
        -configuration Debug \
        -destination "platform=iOS Simulator,name=$device_name,OS=latest" \
        -only-testing:"$TEST_TARGET/$TEST_CLASS" \
        -resultBundlePath "$RESULT_BUNDLE" \
        -quiet \
        2>&1 | tail -5
    set -e

    if [ ! -d "$RESULT_BUNDLE" ]; then
        echo "  ERROR: No result bundle created for $device_name. Skipping."
        continue
    fi

    echo "  Tests complete. Extracting screenshots..."

    # Export attachments from the xcresult bundle
    mkdir -p "$EXPORT_DIR"
    xcrun xcresulttool export attachments \
        --path "$RESULT_BUNDLE" \
        --output-path "$EXPORT_DIR"

    # Organise exported screenshots into the final directory using the manifest
    mkdir -p "$FINAL_DIR"

    if [ -f "$EXPORT_DIR/manifest.json" ]; then
        # Parse manifest.json to rename UUID-named files to human-readable names.
        # The manifest has structure:
        #   [{ "attachments": [{ "exportedFileName": "UUID.png",
        #        "suggestedHumanReadableName": "Name.png", ... }], ... }]

        manifest_content=$(tr -d '\n' < "$EXPORT_DIR/manifest.json")

        echo "$manifest_content" | grep -o '"exportedFileName" *: *"[^"]*" *,[^}]*"suggestedHumanReadableName" *: *"[^"]*"' | while IFS= read -r match; do
            att_file=$(echo "$match" | sed -n 's/.*"exportedFileName" *: *"\([^"]*\)".*/\1/p')
            suggested=$(echo "$match" | sed -n 's/.*"suggestedHumanReadableName" *: *"\([^"]*\)".*/\1/p')

            if [ -n "$att_file" ] && [ -n "$suggested" ] && [ -f "$EXPORT_DIR/$att_file" ]; then
                # Strip any UUID suffix pattern (_0_UUID) from the name for cleaner filenames
                clean_name=$(echo "$suggested" | sed 's/_[0-9]*_[0-9A-F\-]\{36\}\./\./')

                cp "$EXPORT_DIR/$att_file" "$FINAL_DIR/$clean_name"
                echo "    $clean_name"
            fi
        done
    else
        echo "  Warning: No manifest.json found. Copying raw files..."
        cp "$EXPORT_DIR"/*.png "$FINAL_DIR/" 2>/dev/null || true
    fi

    # Clean up intermediate files
    rm -rf "$EXPORT_DIR"
    rm -rf "$RESULT_BUNDLE"

    file_count=$(ls -1 "$FINAL_DIR" 2>/dev/null | wc -l | tr -d ' ')
    echo "  Done: $file_count screenshots saved to $FINAL_DIR/"
    echo ""
done

echo "=== Screenshot capture complete ==="
echo ""
echo "Screenshots are in: $OUTPUT_DIR/"
ls -R "$OUTPUT_DIR/"
