# CalAI - AI-Powered Calorie Tracker

CalAI is an iOS application that uses AI to analyze food photos and estimate their calorie content. Built with SwiftUI and SwiftData, it provides an intuitive way to track your food intake.

## Features
- 📷 Capture food photos with the built-in camera
- 🤖 AI-powered food analysis using OpenAI Vision API
- ✏️ Edit and refine analysis results
- 📅 Track food history with calendar view
- 🔍 Search and filter your food entries

## Requirements
- iOS 17+
- Xcode 15+
- OpenAI API key (for food analysis)

## Installation
1. Clone the repository:
```bash
git clone https://github.com/AppsClicks/CalAI.git
cd CalAI
```

2. Open the project in Xcode:
```bash
open CalAI.xcodeproj
```

3. Set up your OpenAI API key:
   - Open the Settings screen in the app
   - Enter your OpenAI API key
   - Or set it as an environment variable in your scheme:
     ```
     OPENAI_API_KEY=your_api_key_here
     ```

4. Build and run the app in Xcode (⌘R)

## Project Structure
```
CalAI/
├── Models/            # Data models
├── Views/             # SwiftUI views
├── ViewModels/        # View models
├── Services/          # Service classes
├── CalAIApp.swift     # App entry point
└── Preview Content/   # Preview assets
```

## Dependencies
- SwiftUI
- SwiftData
- AVFoundation (for camera)
- Combine (for reactive programming)

## Configuration
The app requires an OpenAI API key for food analysis. You can:
1. Enter it in the Settings screen
2. Set it as an environment variable (`OPENAI_API_KEY`)
3. Add it to a `.env` file in the project root

## Testing
Run the app on:
- iPhone simulator (test different screen sizes)
- Physical device (for camera functionality)

## Contributing
Pull requests are welcome. For major changes, please open an issue first.

## License
[MIT](https://choosealicense.com/licenses/mit/)
