# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a hybrid AI agent system built for the AI Agent Hackathon 2025, consisting of:
- **Backend**: Python-based AI agents using Google's Agent Development Kit (ADK)
- **Frontend**: Flutter mobile application
- **Infrastructure**: Google Cloud Run deployment

## Common Development Commands

### Backend (Python)
```bash
# Install dependencies
poetry install

# Deploy to Google Cloud Run
./deploy.sh

# Run locally (check individual agent files for specific commands)
poetry run python -m learning_agent.agent
```

### Frontend (Flutter)
```bash
# Navigate to Flutter directory
cd front/

# Install dependencies
flutter pub get

# Run on different platforms
flutter run                    # Default platform
flutter run -d chrome          # Web
flutter run -d android         # Android
flutter run -d ios            # iOS

# Build for production
flutter build apk             # Android APK
flutter build ios             # iOS
flutter build web             # Web

# Run tests
flutter test

# Analyze code
flutter analyze
```

## Architecture Overview

### Multi-Agent Learning System
The core learning agent (`learning_agent/agent.py`) orchestrates a 6-step learning process:

1. **Topic Collection** (`topic_hearing.py`) - Gathers learning topics from users
2. **Material Generation** (`material_generator.py`) - Creates educational content
3. **Teaching Support** (`teacher.py`) - Provides learning assistance
4. **Casual Conversation** (`casual_talk.py`) - Handles social interactions
5. **Presentation Listening** (`exam_listener.py`) - Listens to student presentations
6. **Evaluation & Feedback** (`exam_evaluator.py`) - Assesses and provides feedback

Each sub-agent is specialized for specific tasks and coordinated by the root agent.

### Flutter Frontend Architecture
- **API Communication**: `api_client.dart` handles HTTP requests to Python backend
- **Chat Interface**: `chat_page.dart` provides the main user interaction
- **Session Management**: `session_list_widget.dart` and `split_page.dart` manage user sessions
- **User Persistence**: Uses SharedPreferences for local storage and UUID for user identification

### Key Integration Points
- Flutter app communicates with Python agents via HTTP API
- User sessions are managed with UUID-based identification
- Attachments (images/audio) are supported in the chat interface
- Firebase integration for crashlytics and core services

## Configuration Files

### Python Configuration
- `pyproject.toml` - Poetry dependencies and project settings
- `learning_agent/config.py` - AI model configuration using LiteLLM
- `deploy.sh` - Google Cloud deployment script with environment variables

### Flutter Configuration  
- `front/pubspec.yaml` - Flutter dependencies and project settings
- Platform-specific configs in `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/`

## Development Notes

### Backend Dependencies
- Python 3.12+ required
- Google ADK for agent framework
- LiteLLM for AI model integration

### Frontend Dependencies
- Flutter SDK 3.8.1+
- Key packages: `flutter_ai_toolkit`, `http`, `shared_preferences`, `uuid`, Firebase

### Deployment
- Backend deploys to Google Cloud Run in `asia-northeast1` region
- Project ID: `local-dev-226505`
- Service name: `prototype`
- UI deployment included with `--with_ui` flag