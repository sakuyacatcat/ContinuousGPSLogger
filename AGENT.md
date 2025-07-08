# AGENT.md

This file provides guidance to coding agents when working with code in this repository.

## Project Overview

This is a SwiftUI iOS application for continuous GPS logging. The app is designed to track location data in the background and store it persistently, with features for viewing location history and exporting data.

## Architecture

- **SwiftUI + iOS 18+**: Modern declarative UI framework
- **Core Location**: GPS tracking with background location updates
- **Core Data**: Local persistence for location points
- **Background Tasks**: Processing and flush operations for continuous logging
- **MVVM Pattern**: ViewModels handle business logic and data flow

### Key Components Structure

```
ContinuousGPSLogger/
├── ContinuousGPSLoggerApp.swift     # Main app entry point
├── ContentView.swift                # Main UI view
├── Info.plist                       # App permissions and background modes
└── (To be implemented):
    ├── Services/
    │   ├── LocationService.swift    # Core Location management
    │   ├── PersistenceService.swift # Core Data operations
    │   └── MotionService.swift      # Optional motion detection
    ├── ViewModels/
    │   └── LocationViewModel.swift  # Location data binding
    └── Views/
        ├── MainView.swift           # Map and current location
        └── HistoryView.swift        # Location history list
```

## Development Commands

### Building and Running

```bash
# Build the project
xcodebuild -scheme ContinuousGPSLogger -configuration Debug build

# Run tests
xcodebuild -scheme ContinuousGPSLogger -configuration Debug test

# Clean build folder
xcodebuild -scheme ContinuousGPSLogger clean
```

### Xcode Development

- Open `ContinuousGPSLogger.xcodeproj` in Xcode
- Main scheme: `ContinuousGPSLogger`
- Available targets: `ContinuousGPSLogger`, `ContinuousGPSLoggerTests`, `ContinuousGPSLoggerUITests`
- Default build configuration: Release

## Key Implementation Details

### Background Location Permissions

- App requires "Always" location permission for continuous tracking
- Background modes enabled: `location`, `fetch`, `processing`
- Location usage descriptions in Japanese in Info.plist

### Location Service Requirements

- Use `CLLocationManager` with `desiredAccuracy = kCLLocationAccuracyBest`
- Enable `allowsBackgroundLocationUpdates = true`
- Implement `startMonitoringSignificantLocationChanges()` for app resurrection
- For iOS 18+: Use `CLLocationUpdate.liveUpdates()` async sequence
- For older iOS: Use delegate-based `startUpdatingLocation()`

### Data Persistence

- Core Data model with `TrackPoint` entity
- Attributes: `timestamp`, `lat`, `lon`, `hAcc`, `speed`, `id`
- Background task scheduling for periodic data flush
- Consider SwiftData migration for iOS 18+ features

### Background Task Management

- Register `BGProcessingTaskRequest` with identifier "flush"
- Schedule 15-minute intervals for data persistence
- Handle app termination and significant location changes

## Design Document Reference

Comprehensive implementation roadmap available in `docs/designDocument.md` with 46 detailed steps covering:

- Project setup and capabilities configuration
- Core Location and background modes implementation
- Data persistence with Core Data
- SwiftUI views and ViewModels
- Background task scheduling
- Testing and deployment to TestFlight

## Testing Strategy

- Use custom GPX files in iOS Simulator for location testing
- Test background fetch simulation via Xcode Debug menu
- Verify app resurrection after device restart and significant location changes
- Test user app termination scenarios and recovery

## Release Considerations

- App Store review requires detailed explanation for "Always" location permission
- Include screenshots demonstrating location tracking purpose
- Battery optimization and background location best practices
- TestFlight testing for real-world background behavior validation

## Principles to Follow

- John Carmack, Robert C. Martin, Rob Pike ならどう設計するかを意識せよ。
- 小さく、シンプルに保つこと。
- 変更に強い設計を心がける。
- t-wada の TDD（Test-Driven Development）を実践する。
