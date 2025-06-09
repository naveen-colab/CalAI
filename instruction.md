# CalAI Product Requirements Document

## Overview
CalAI is an iOS application that analyzes food photos to estimate calorie and nutrient content using OpenAI's Vision API. Users can capture food images, review and edit the analysis results, and track their food intake over time.

## Features

### Core Features
1. **Food Photo Capture**
   - Camera interface with flash control
   - Image preview and retake functionality

2. **AI Food Analysis**
   - Integration with OpenAI Vision API
   - Automatic identification of food items and ingredients
   - Calorie estimation based on visual analysis

3. **Food Entry Management**
   - Editable food name, calories, and notes
   - Ingredient list with quantity and calorie details
   - Manual entry option when analysis isn't available

4. **History Tracking**
   - Calendar-based food log
   - Filtering by date ranges (day/week/month/all)
   - Search functionality
   - Daily calorie totals

5. **Settings**
   - API key configuration
   - App information and documentation links

## Technical Specifications

### Data Models
- `FoodEntry`: Stores food name, timestamp, image, calories, and notes
- `Ingredient`: Stores ingredient details with name, quantity, and calories

### Architecture
- MVVM (Model-View-ViewModel) pattern
- SwiftData for local persistence
- Combine for reactive programming

### Dependencies
- OpenAI Vision API
- AVFoundation for camera functionality
- SwiftUI for UI components

## API Integration
The app uses OpenAI's GPT-4 Vision API with the following request structure:
```json
{
  "model": "gpt-4-vision-preview",
  "messages": [
    {
      "role": "user",
      "content": [
        {"type": "text", "text": "Analyze this food..."},
        {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,..."}}
      ]
    }
  ],
  "max_tokens": 1000
}
```

### Expected Response Structure
```json
{
  "name": "analyze_food_image",
  "strict": true,
  "schema": {
    "type": "object",
    "properties": {
      "parameters": {
        "type": "object",
        "properties": {
          "food_name": {
            "type": "string",
            "description": "Name of the food item"
          },
          "food_description": {
            "type": "string",
            "description": "Description of the food item"
          },
          "ingredients": {
            "type": "array",
            "description": "Array of ingredients in the food item",
            "items": {
              "type": "object",
              "properties": {
                "name": {
                  "type": "string",
                  "description": "Name of the ingredient"
                },
                "calorie_per_gram": {
                  "type": "number",
                  "description": "Calories per gram of the ingredient"
                },
                "total_grams": {
                  "type": "number",
                  "description": "Total grams of the ingredient"
                },
                "total_calories": {
                  "type": "number",
                  "description": "Total calories from this ingredient"
                }
              },
              "required": [
                "name",
                "calorie_per_gram",
                "total_grams",
                "total_calories"
              ],
              "additionalProperties": false
            }
          }
        },
        "required": [
          "food_name",
          "food_description",
          "ingredients"
        ],
        "additionalProperties": false
      }
    },
    "required": [
      "parameters"
    ],
    "additionalProperties": false
  }
}
```

## Testing Requirements
1. Camera functionality on physical devices
2. API response parsing and error handling
3. Data persistence and retrieval
4. UI responsiveness across device sizes
