//
//  ViewController.swift
//  Fish
//
//  Created by Andrew Carter on 11/30/17.
//  Copyright © 2017 Andrew Carter. All rights reserved.
//

import UIKit
import GameKit

final class ViewController: UIViewController, UICollisionBehaviorDelegate {
    
    // MARK: - Properties
    
    @IBOutlet var targetContainerView: UIView!
    @IBOutlet var targetView: UIView!
    @IBOutlet var progressContainerView: UIView!
    @IBOutlet var progressView: UIView!
    @IBOutlet var progressViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var fishView: UIView!
    var targetAnimator: UIDynamicAnimator!
    var targetPushBehavior: UIPushBehavior!
    var fishPushBehavior: UIPushBehavior!
    var fishPushTimer: Timer!
    var progressTimer: Timer!
    let heavyFeedbackGenerator = UIImpactFeedbackGenerator(style: UIImpactFeedbackStyle.heavy)
    let lightFeedbackGenerator = UIImpactFeedbackGenerator(style: UIImpactFeedbackStyle.light)
    var wasTargetting = false
    var audioPlayer: AVAudioPlayer!

    // MARK: - Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTargetAnimator()
        setupFishPushTimer()
        setupProgressTimer()
        setupAudioPlayer()
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeLeft
    }
    
    // MARK: - Instance Methods
    
    private func setupAudioPlayer() {
        let url = Bundle.main.url(forResource: "town", withExtension: "mp3")!
        audioPlayer = try! AVAudioPlayer(contentsOf: url)
        audioPlayer.play()
    }
    
    private func setupProgressTimer() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            self?.progressTimerTick(timer: timer)
        }
    }
    
    private func setupFishPushTimer() {
        fishPushTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] timer in
            self?.fishTimerTick(timer: timer)
        }
    }
    
    private func progressTimerTick(timer: Timer) {
        let minHeight: CGFloat = 0.0
        let maxHeight: CGFloat = progressContainerView.bounds.height
        let currentHeight: CGFloat = progressViewHeightConstraint.constant
        let delta: CGFloat = 5.0
        let intersects = fishView.frame.intersects(targetView.frame)
        
        let newHeight: CGFloat?
        if intersects,
            currentHeight + delta <= maxHeight {
            newHeight = currentHeight + delta
            
            if !wasTargetting {
                heavyFeedbackGenerator.impactOccurred()
            }
            wasTargetting = true
        } else if !intersects,
            currentHeight - delta >= minHeight {
            newHeight = currentHeight - delta
            
            if wasTargetting {
                heavyFeedbackGenerator.impactOccurred()
            }
            wasTargetting = false
        } else {
            newHeight = nil
        }
        
        if let newHeight = newHeight {
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
                self.progressViewHeightConstraint.constant = newHeight
                self.progressContainerView.layoutIfNeeded()
            })
        }
    }
    
    private func fishTimerTick(timer: Timer) {
        let randomSource = GKARC4RandomSource()
        guard randomSource.nextBool() else {
            return
        }
        
        let pushDirectionMultiplier: CGFloat = randomSource.nextInt(upperBound: 2) < 1 ? -1.0 : 1.0
        fishPushBehavior.pushDirection = CGVector(dx: 0.0, dy: 0.5 * pushDirectionMultiplier)
        fishPushBehavior.magnitude = CGFloat(2.0 + randomSource.nextUniform()) + CGFloat(randomSource.nextInt(upperBound: 5))
        fishPushBehavior.active = true
    }
    
    private func setupTargetAnimator() {
        targetAnimator = UIDynamicAnimator(referenceView: targetContainerView)
        
        let gravityBehavior = UIGravityBehavior(items: [targetView])
        targetAnimator.addBehavior(gravityBehavior)
        
        let collisionBehavior = UICollisionBehavior(items: [targetView, fishView])
        collisionBehavior.collisionMode = .boundaries
        collisionBehavior.translatesReferenceBoundsIntoBoundary = true
        targetAnimator.addBehavior(collisionBehavior)
        
        targetPushBehavior = UIPushBehavior(items: [targetView], mode: .continuous)
        targetPushBehavior.pushDirection = CGVector(dx: 0.0, dy: -1.0)
        targetPushBehavior.magnitude = 5.0
        targetPushBehavior.active = false
        targetAnimator.addBehavior(targetPushBehavior)
        
        fishPushBehavior = UIPushBehavior(items: [fishView], mode: .instantaneous)
        fishPushBehavior.active = false
        targetAnimator.addBehavior(fishPushBehavior)
        
        let fishBehavior = UIDynamicItemBehavior(items: [fishView])
        fishBehavior.density = 10.0
        fishBehavior.resistance = 3.0
        targetAnimator.addBehavior(fishBehavior)
        
        let fishTargetedBehavior = UICollisionBehavior(items: [fishView, targetView])
        fishTargetedBehavior.collisionMode = .items
        fishTargetedBehavior.collisionDelegate = self
        
        let targetBehavior = UIDynamicItemBehavior(items: [targetView])
        targetBehavior.elasticity = 0.5
        targetAnimator.addBehavior(targetBehavior)
    }
    
    @IBAction private func targetButtonTouchDown() {
        targetPushBehavior.active = true
    }
    
    @IBAction private func targetButtonTouchUp() {
        targetPushBehavior.active = false
    }
    
}

