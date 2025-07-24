//
//  CurrentLocationView.swift
//  ContinuousGPSLogger
//
//  Created by Claude on 2025/07/24.
//

import SwiftUI
import CoreLocation

struct CurrentLocationView: View {
    @ObservedObject var locationService: LocationService
    
    var body: some View {
        Section(LocalizedStrings.Sections.currentLocation) {
            if let c = locationService.current {
                VStack(alignment: .leading, spacing: AppConstants.UI.sectionSpacing) {
                    InfoRowView(
                        label: LocalizedStrings.Location.latitude,
                        value: String(format: AppConstants.Formatting.coordinateDecimalPlaces, c.coordinate.latitude)
                    )
                    
                    InfoRowView(
                        label: LocalizedStrings.Location.longitude, 
                        value: String(format: AppConstants.Formatting.coordinateDecimalPlaces, c.coordinate.longitude)
                    )
                    
                    if c.horizontalAccuracy > 0 {
                        InfoRowView(
                            label: LocalizedStrings.Location.accuracy,
                            value: String(format: AppConstants.Formatting.accuracyDecimalPlaces, c.horizontalAccuracy) + LocalizedStrings.Units.meters
                        )
                    }
                    
                    if c.speed >= 0 {
                        InfoRowView(
                            label: LocalizedStrings.Location.speed,
                            value: String(format: AppConstants.Formatting.speedDecimalPlaces, c.speed * AppConstants.Formatting.kmhConversionFactor) + LocalizedStrings.Units.kmh
                        )
                    }
                    
                    InfoRowView(
                        label: LocalizedStrings.Location.updateTime,
                        value: c.timestamp.formatted(.dateTime.hour().minute().second())
                    )
                }
            } else {
                HStack {
                    ProgressView()
                        .scaleEffect(AppConstants.UI.progressViewScale)
                    Text(LocalizedStrings.Location.obtaining)
                }
            }
        }
    }
}

#Preview {
    Form {
        CurrentLocationView(locationService: LocationService.shared)
    }
}