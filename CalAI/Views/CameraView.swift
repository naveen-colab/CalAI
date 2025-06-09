//
//  CameraView.swift
//  CalAI
//
//  Created by Surya Teja Nammi on 6/8/25.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    @State private var navigateToAnalysis = false
    
    var body: some View {
        ZStack {
            // Main content
            if viewModel.capturedImage != nil {
                // Show captured image
                imagePreviewView
            } else {
                let _ = print("Image preview is shown")
                // Show camera preview
                cameraPreviewView
            }
            
            // Camera controls overlay
            VStack {
                Spacer()
                
                if viewModel.capturedImage == nil {
                    // Camera controls
                    cameraControlsView
                } else {
                    
                    // Image preview controls
                    imageControlsView
                }
            }
            .padding(.bottom, 30)
            
            // Processing overlay
            if viewModel.isProcessing {
                processingOverlay
            }
        }
        .fullScreenCover(isPresented: $navigateToAnalysis) {
            if let image = viewModel.capturedImage {
                NavigationStack {
                    FoodAnalysisView(uiImage: image)
                }
            }
        }
        .onChange(of: navigateToAnalysis) { newValue in
            if !navigateToAnalysis {
                viewModel.capturedImage = nil
                viewModel.startSession()
            }
        }
        .alert(viewModel.alertMessage, isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) {}
        }
        .onAppear {
            viewModel.startSession()
        }
        .onDisappear {
            viewModel.stopSession()
        }
    }
    
    // MARK: - Camera Preview
    private var cameraPreviewView: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if viewModel.cameraPermissionGranted && !viewModel.isCameraUnavailable {
                CameraPreviewRepresentable(session: viewModel.session)
                    .edgesIgnoringSafeArea(.all)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "camera.metering.unknown")
                        .font(.system(size: 72))
                        .foregroundColor(.white)
                    
                    Text(viewModel.cameraPermissionGranted ? "Camera unavailable" : "Camera access required")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Button {
                        if !viewModel.cameraPermissionGranted {
                            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                        } else {
                            viewModel.setupCamera()
                        }
                    } label: {
                        Text(viewModel.cameraPermissionGranted ? "Try Again" : "Open Settings")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Camera Controls
    private var cameraControlsView: some View {
        HStack(spacing: 60) {
            // Flash toggle
            Button {
                viewModel.toggleFlash()
            } label: {
                Image(systemName: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            
            // Capture button
            Button {
                viewModel.capturePhoto()
            } label: {
                Circle()
                    .strokeBorder(Color.white, lineWidth: 3)
                    .frame(width: 80, height: 80)
                    .background(Circle().fill(Color.white.opacity(0.2)))
            }
            
            // Placeholder for symmetry
            Circle()
                .fill(Color.clear)
                .frame(width: 50, height: 50)
        }
    }
    
    // MARK: - Image Preview
    private var imagePreviewView: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if let image = viewModel.capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .edgesIgnoringSafeArea(.all)
            }
        }
    }
    
    // MARK: - Image Controls
    private var imageControlsView: some View {
        HStack(spacing: 60) {
            // Retake button
            Button {
                viewModel.retakePhoto()
            } label: {
                Text("Retake")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.7))
                    .cornerRadius(10)
            }
            
            // Use photo button
            Button {
                navigateToAnalysis = true
                print("Analyse is clicked")
            } label: {
                Text("Analyze")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.green.opacity(0.7))
                    .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Processing Overlay
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Analyzing image...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Camera Preview Representable
struct CameraPreviewRepresentable: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: CGRect.zero)
        view.backgroundColor = .black
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer else { return }
        previewLayer.frame = uiView.bounds
        previewLayer.session = session
    }
}

#Preview {
    NavigationStack {
        CameraView()
    }
}
