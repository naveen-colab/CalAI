//
//  OpenAIService.swift
//  CalAI
//
//  Created by Surya Teja Nammi on 6/8/25.
//

import Foundation
import UIKit
import Combine

class OpenAIService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    init() {
        self.apiKey = ""
        print("OpenAIService initialized with API key")
    }
    
    func analyzeFood(image: UIImage) -> AnyPublisher<FoodAnalysisResponse, Error> {
        guard let compressedImageData = compressImage(image) else {
            return Fail(error: NSError(domain: "OpenAIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"]))
                .eraseToAnyPublisher()
        }
        
        let base64Image = compressedImageData.base64EncodedString()
        print("Base64 image length: \(base64Image.count) characters")
        
        // Verify base64 is valid
        guard Data(base64Encoded: base64Image) != nil else {
            return Fail(error: NSError(domain: "OpenAIService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid base64 encoding"]))
                .eraseToAnyPublisher()
        }
        
        let prompt = """
        Analyze this food image and provide detailed nutritional information.
        Return a JSON object with the following EXACT structure:
        {
            "foodName": "Name of the dish",
            "foodDescription": "Description of the dish",
            "calories": 123,
            "ingredients": [
                {
                    "name": "Ingredient name",
                    "calorie_per_gram": 1.5,
                    "total_grams": 100,
                    "total_calories": 150
                }
            ]
        }
        Important rules:
        1. MUST include all fields exactly as shown
        2. calorie_per_gram should be in calories per gram
        3. total_grams should be the estimated weight in grams
        4. total_calories should be calorie_per_gram * total_grams
        5. Be as accurate as possible with the nutritional analysis
        """
        
        let requestBody: [String: Any] = [
            "model": "gpt-4.1-mini",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": prompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 1000
        ]
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        // Print request details for debugging
        print("API Request:")
        print("URL: \(request.url?.absoluteString ?? "nil")")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("Request Body: \(bodyString)")
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .handleEvents(
                receiveOutput: { (data, response) in
                    print("Raw API Response:")
                    print("Status Code: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Response Data: \(responseString)")
                    }
                }
            )
            .tryMap { (data, response) -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    let errorString = String(data: data, encoding: .utf8) ?? "Unable to decode error response"
                    throw NSError(domain: "OpenAIService", code: 1, userInfo: [
                        NSLocalizedDescriptionKey: "API request failed: \(errorString)"
                    ])
                }
                return data
            }
            .decode(type: OpenAIResponse.self, decoder: JSONDecoder())
            .tryMap { response -> FoodAnalysisResponse in
                guard let choice = response.choices.first,
                      let content = choice.message.content else {
                    throw NSError(domain: "OpenAIService", code: 2, userInfo: [
                        NSLocalizedDescriptionKey: "Invalid response format from API"
                    ])
                }

                // Try to extract JSON from response
                guard let jsonStart = content.range(of: "{"),
                      let jsonEnd = content.range(of: "}", options: .backwards) else {
                    throw NSError(domain: "OpenAIService", code: 3, userInfo: [
                        NSLocalizedDescriptionKey: "Could not find JSON in response: \(content)"
                    ])
                }

                let jsonString = String(content[jsonStart.lowerBound..<jsonEnd.upperBound])
                print("Extracted JSON: \(jsonString)")

                do {
                    return try JSONDecoder().decode(FoodAnalysisResponse.self, from: jsonString.data(using: .utf8)!)
                } catch {
                    print("JSON Decoding Error: \(error)")
                    throw error
                }
            }
            .eraseToAnyPublisher()
    }
    
    private func compressImage(_ image: UIImage, maxSizeKB: Int = 1000) -> Data? {
        // Start with high quality
        var compression: CGFloat = 0.8
        var imageData = image.jpegData(compressionQuality: compression)
        
        // Reduce size if needed
        while let data = imageData, data.count > maxSizeKB * 1024 && compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }
        
        // If still too large, resize the image
        if let data = imageData, data.count > maxSizeKB * 1024 {
            let scale = sqrt(Double(maxSizeKB * 1024) / Double(data.count))
            let newSize = CGSize(width: Double(image.size.width) * scale, height: Double(image.size.height) * scale)
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return resizedImage?.jpegData(compressionQuality: compression)
        }
        
        return imageData
    }
}

// MARK: - Response Models
struct OpenAIResponse: Decodable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    
    struct Choice: Decodable {
        let index: Int
        let message: Message
        let finishReason: String?
        
        enum CodingKeys: String, CodingKey {
            case index, message
            case finishReason = "finish_reason"
        }
    }
    
    struct Message: Decodable {
        let role: String
        let content: String?
    }
}

struct FoodAnalysisResponse: Codable {
    let foodName: String
    let foodDescription: String
    let calories: Double
    let ingredients: [IngredientInfo]
    
    struct IngredientInfo: Codable {
        let name: String
        let calorie_per_gram: Double
        let total_grams: Double
        let total_calories: Double
    }
}
