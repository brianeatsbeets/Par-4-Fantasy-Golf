//
//  UIViewController Extensions.swift
//  Par 4 Fantasy Golf
//
//  Created by Aguirre, Brian P. on 4/26/23.
//

import UIKit

// This extension contains functions to display and hide loading indicators
extension UIViewController {
    
    // Display an alert with a spinning loading indicator and a message
    func displayLoadingIndicator(animated: Bool) {
        
        // Identify the window to which we'll add the loading indicatory view and verify that a loading indicator view isn't already active
        // Using window instead of view to cover the entire screen, including the nav bar
        let scenes = UIApplication.shared.connectedScenes
        guard let windowScene = scenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              window.viewWithTag(100) == nil else { return }
        
        // Create and configure the UIActivityIndicatorView
        let loadingIndicatorView = UIActivityIndicatorView(frame: window.bounds)
        loadingIndicatorView.style = .large
        loadingIndicatorView.backgroundColor = .white.withAlphaComponent(0.7)
        loadingIndicatorView.alpha = animated ? 0 : 1
        loadingIndicatorView.startAnimating()
        loadingIndicatorView.tag = 100
        
        // Add the loading indicator view to the window
        window.addSubview(loadingIndicatorView)
        
        // Animate the appearance
        if animated {
            UIView.animate(withDuration: 0.15) {
                loadingIndicatorView.alpha = 1
            }
        }
    }
    
    // Dismiss the loading indicator alert
    func dismissLoadingIndicator(animated: Bool) {
        
        // Identify the window from which we'll remove the loading indicatory view, along with the existing loading indicator view
        let scenes = UIApplication.shared.connectedScenes
        guard let windowScene = scenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let loadingIndicatorView = window.viewWithTag(100) else { return }
        
        // Remove the loading indicator view, animating if required
        if animated {
            UIView.animate(withDuration: 0.15, animations: {
                loadingIndicatorView.alpha = 0
            }, completion: { _ in
                loadingIndicatorView.removeFromSuperview()
            })
        } else {
            loadingIndicatorView.removeFromSuperview()
        }
    }
}
