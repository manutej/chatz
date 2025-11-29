#!/bin/bash

# Code generation script for Chatz app
# Generates JSON serialization code for models

echo "Starting code generation..."

# Run build_runner to generate .g.dart files
flutter pub run build_runner build --delete-conflicting-outputs

echo "Code generation complete!"
echo ""
echo "Generated files:"
echo "  - lib/features/chat/data/models/message_model.g.dart"
echo "  - lib/features/chat/data/models/participant_model.g.dart"
echo "  - lib/features/chat/data/models/chat_model.g.dart"
