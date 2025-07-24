//
//  PermissionStatusView.swift
//  ContinuousGPSLogger
//
//  Created by Claude on 2025/07/24.
//

import SwiftUI
import CoreLocation

struct PermissionStatusView: View {
    @ObservedObject var locationService: LocationService
    
    var body: some View {
        Section(LocalizedStrings.Sections.permissionStatus) {
            StatusIndicatorView(
                label: LocalizedStrings.Permission.locationPermission,
                status: locationService.authorizationStatus.localizedText,
                statusColor: authorizationStatusColor
            )
            
            StatusIndicatorView(
                label: LocalizedStrings.Permission.trackingStatus,
                status: locationService.isTracking ? LocalizedStrings.Permission.tracking : LocalizedStrings.Permission.stopped,
                statusColor: locationService.isTracking ? .green : .gray
            )
            
            if locationService.permissionRequestInProgress {
                StatusIndicatorView(
                    label: "",
                    status: LocalizedStrings.Permission.requesting,
                    statusColor: .secondary,
                    showProgressIndicator: true
                )
            }
            
            VStack(alignment: .leading, spacing: AppConstants.UI.sectionSpacing) {
                Text(locationService.authorizationStatus.guidanceText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if locationService.needsAlwaysPermission {
                    ActionButtonView(
                        title: LocalizedStrings.Permission.requestAlways,
                        style: .prominent,
                        isDisabled: locationService.permissionRequestInProgress
                    ) {
                        locationService.requestAlwaysPermission()
                    }
                } else if locationService.authorizationStatus == .denied {
                    ActionButtonView(
                        title: LocalizedStrings.Permission.openSettings,
                        style: .bordered
                    ) {
                        locationService.openSettings()
                    }
                }
            }
        }
    }
    
    private var authorizationStatusColor: Color {
        switch locationService.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return .green
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .gray
        }
    }
}

#Preview {
    Form {
        PermissionStatusView(locationService: LocationService.shared)
    }
}