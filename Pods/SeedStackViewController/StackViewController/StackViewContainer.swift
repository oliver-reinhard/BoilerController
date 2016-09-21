//
//  StackViewContainer.swift
//  StackViewController
//
//  Created by Indragie Karunaratne on 2016-04-11.
//  Copyright © 2016 Seed Platform, Inc. All rights reserved.
//

import UIKit

/// A container for a `UIStackView` that adds some additional capabilities, including
/// being able to change the background color, assigning a background view, and
/// using view controller composition to display content.
public class StackViewContainer: UIView, UIScrollViewDelegate {
    /// The scroll view that is the superview of the stack view.
    public let scrollView: AutoScrollView
    
    /// The stack view. It is not safe to modify the arranged subviews directly
    /// via the stack view. The content view collection accessors on
    /// `StackViewContainer` should be used instead. It is also not safe to modify
    /// the `axis` property. `StackViewContainer.axis` should be set instead.
    public let stackView: UIStackView
    
    private let backgroundColorContainerView = UIView(frame: CGRectZero)
    
    /// An optional background view that is shown behind the stack view. The
    /// top of the background view will be kept pinned to the top of the scroll
    /// view bounds, even when bouncing.
    public var backgroundView: UIView? {
        get { return _backgroundView }
        set {
            backgroundViewTopConstraint = nil
            _backgroundView?.removeFromSuperview()
            _backgroundView = newValue
            layoutBackgroundView()
        }
    }
    private var _backgroundView: UIView?
    private var backgroundViewTopConstraint: NSLayoutConstraint?
    
    /// The content views that are displayed inside the stack view. This array
    /// does not include separator views that are automatically inserted by
    /// the container if the `separatorViewFactory` property is set.
    ///
    /// Setting this array causes all of the existing content views in the 
    /// stack view to be removed and replaced with the new content views.
    public var contentViews: [UIView] {
        get { return _contentViews }
        set {
            _contentViews = newValue
            relayoutContent(true)
        }
    }
    private var _contentViews = [UIView]()
    
    private var items = [Item]()
    public var separatorViewFactory: SeparatorViewFactory? {
        didSet { relayoutContent(false) }
    }
    
    /// Creates a separator view factory that uses the `SeparatorView` class
    /// provided by this framework to render the view. The separator will
    /// automatically use the correct orientation based on the orientation
    /// of the stack view. The `configurator` block can be used to customize
    /// the appearance of the separator.
    public static func createSeparatorViewFactory(configurator: (SeparatorView -> Void)? = nil) -> SeparatorViewFactory {
        return { axis in
            let separatorAxis: UILayoutConstraintAxis = {
                switch axis {
                case .Horizontal: return .Vertical
                case .Vertical: return .Horizontal
                }
            }()
            let separatorView = SeparatorView(axis: separatorAxis)
            configurator?(separatorView)
            return separatorView
        }
    }
    
    /// The axis (direction) that content is laid out in. Setting the axis via
    /// this property instead of `stackView.axis` ensures that any separator
    /// views are recreated to account for the change in layout direction.
    public var axis: UILayoutConstraintAxis {
        get { return stackView.axis }
        set {
            stackView.axis = newValue
            updateSizeConstraint()
            relayoutContent(false)
        }
    }
    private var stackViewSizeConstraint: NSLayoutConstraint?
    
    public override var backgroundColor: UIColor? {
        didSet {
            scrollView.backgroundColor = backgroundColor
            backgroundColorContainerView.backgroundColor = backgroundColor
        }
    }
    
    public typealias SeparatorViewFactory = UILayoutConstraintAxis -> UIView
    
    /// Initializes an instance of `StackViewContainer` using a stack view
    /// with the default configuration, which is simply a `UIStackView` with
    /// all of its properties set to the default values except for `axis`, which
    /// is set to `.Vertical`.
    public convenience init() {
        self.init(stackView: constructDefaultStackView())
    }
    
    /// Initializes an instance of `StackViewContainer` using an existing
    /// instance of `UIStackView`. Any existing arranged subviews of the stack
    /// view are removed prior to `StackViewContainer` taking ownership of it.
    public init(stackView: UIStackView) {
        stackView.removeAllArrangedSubviews()
        self.stackView = stackView
        self.scrollView = AutoScrollView(frame: CGRectZero)
        super.init(frame: CGRectZero)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        stackView = constructDefaultStackView()
        scrollView = AutoScrollView(frame: CGRectZero)
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        backgroundColorContainerView.addSubview(stackView)
        stackView.activateSuperviewHuggingConstraints()
        scrollView.contentView = backgroundColorContainerView
        scrollView.delegate = self
        addSubview(scrollView)
        scrollView.activateSuperviewHuggingConstraints()
        updateSizeConstraint()
    }
    
    private func updateSizeConstraint() {
        stackViewSizeConstraint?.active = false
        let attribute: NSLayoutAttribute = {
            switch axis {
            case .Horizontal: return .Height
            case .Vertical: return .Width
            }
        }()
        stackViewSizeConstraint =
            NSLayoutConstraint(item: stackView, attribute: attribute, relatedBy: .Equal, toItem: scrollView, attribute: attribute, multiplier: 1.0, constant: 0.0)
        stackViewSizeConstraint?.active = true
    }
    
    private func layoutBackgroundView() {
        guard let backgroundView = _backgroundView else { return }
        scrollView.insertSubview(backgroundView, atIndex: 0)
        
        let constraints = backgroundView.activateSuperviewHuggingConstraints()
        for constraint in constraints {
            if constraint.firstAttribute == .Top {
                backgroundViewTopConstraint = constraint
                break
            }
        }
    }
    
    // MARK: Managing Content
    
    /**
     Adds a content view to the list of content views that this container
     manages.
     
     - parameter view:             The content view to add
     - parameter canShowSeparator: See the documentation for
     `StackViewContainer.setCanShowSeparator(:forContentViewAtIndex:)` for more
     details on this parameter.
     */
    public func addContentView(view: UIView, canShowSeparator: Bool = true) {
        insertContentView(view, atIndex: items.endIndex, canShowSeparator: canShowSeparator)
    }
    
    /**
     Inserts a content view into the list of content views that this container
     manages.
     
     - parameter view:             The content view to insert
     - parameter index:            The index to insert the content view at, in
     the `contentViews` array
     - parameter canShowSeparator: See the documentation for
     `StackViewContainer.setCanShowSeparator(:forContentViewAtIndex:)` for more
     details on this parameter.
     */
    public func insertContentView(view: UIView, atIndex index: Int, canShowSeparator: Bool = true) {
        precondition(index >= items.startIndex)
        precondition(index <= items.endIndex)
        
        let stackInsertionIndex: Int
        if items.isEmpty {
            stackInsertionIndex = 0
        } else {
            let lastExistingIndex = items.endIndex.predecessor()
            let lastItem = items[lastExistingIndex]
            if index == lastExistingIndex {
                // If a content view is inserted at (items.count - 1), the last
                // content item will become the final item in the list, in which
                // case its separator should be removed.
                if let separatorView = lastItem.separatorView {
                    stackView.removeArrangedSubview(separatorView)
                    lastItem.separatorView = nil
                }
                stackInsertionIndex = indexOfArrangedSubview(lastItem.contentView)
            } else if index == items.endIndex {
                // If a content view is being inserted at the end of the list, the
                // item before it should have a separator added.
                if lastItem.separatorView == nil && lastItem.canShowSeparator {
                    if let separatorView = createSeparatorView() {
                        lastItem.separatorView = separatorView
                        stackView.addArrangedSubview(separatorView)
                    }
                }
                stackInsertionIndex = stackView.arrangedSubviews.endIndex
            } else {
                stackInsertionIndex = indexOfArrangedSubview(items[index].contentView)
            }
        }
        
        let separatorView: UIView?
        // Only show the separator if the item is not the last item in the list
        if canShowSeparator && index < items.endIndex {
            separatorView = createSeparatorView()
        } else {
            separatorView = nil
        }
        
        let item = Item(
            contentView: view,
            canShowSeparator: canShowSeparator,
            separatorView: separatorView
        )
        items.insert(item, atIndex: index)
        _contentViews.insert(view, atIndex: index)
        stackView.insertArrangedSubview(view, atIndex: stackInsertionIndex)
        if let separatorView = separatorView {
            stackView.insertArrangedSubview(separatorView, atIndex: stackInsertionIndex.successor())
        }
    }
    
    private func indexOfArrangedSubview(subview: UIView) -> Int {
        if let index = stackView.arrangedSubviews.indexOf({ $0 === subview }) {
            return index
        } else {
            fatalError("Called indexOfArrangedSubview with subview that doesn't exist in stackView.arrangedSubviews")
        }
    }
    
    /**
     Removes a content view from the list of content views managed by this container.
     If `view` does not exist in `contentViews`, this method does nothing.
     
     - parameter view: The content view to remove
     */
    public func removeContentView(view: UIView) {
        guard let index = _contentViews.indexOf({ $0 === view }) else { return }
        removeContentViewAtIndex(index)
    }
    
    /**
     Removes a content view from the list of content views managed by this container.
     
     - parameter index: The index of the content view to remove
     */
    public func removeContentViewAtIndex(index: Int) {
        precondition(index >= items.startIndex)
        precondition(index < items.endIndex)
        
        let item = items[index]
        if items.count >= 1 && index == items.endIndex.predecessor() {
            let previousItem = items[index.predecessor()]
            if let separatorView = previousItem.separatorView {
                stackView.removeArrangedSubview(separatorView)
                previousItem.separatorView = nil
            }
        }
        stackView.removeArrangedSubview(item.contentView)
        if let separatorView = item.separatorView {
            stackView.removeArrangedSubview(separatorView)
        }
        items.removeAtIndex(index)
        _contentViews.removeAtIndex(index)
    }
    
    /**
     Controls the visibility of the separator view that comes after a content view.
     If `view` does not exist in `contentViews`, this method does nothing.
     
     - parameter canShowSeparator: See the documentation for
     `StackViewContainer.setCanShowSeparator(:forContentViewAtIndex:)` for more
     details on this parameter.
     - parameter view:             The content view for which to set separator
     visibility.
     */
    public func setCanShowSeparator(canShowSeparator: Bool, forContentView view: UIView) {
        guard let index = _contentViews.indexOf({ $0 === view }) else { return }
        setCanShowSeparator(canShowSeparator, forContentViewAtIndex: index)
    }
    
    /**
     Controls the visibility of the separator view that comes after a content view.
     
     - parameter canShowSeparator: Whether it is possible for the content view
     to show a separator view *after* it (i.e. to the right of the content view
     if the stack view orientation is horizontal, and to the bottom of the
     content view if the stack view orientation is vertical). A separator will
     not be shown if the content view is the last content view in the list.
     - parameter index:            The index of the content view for which to
     set separator visibility.
     */
    public func setCanShowSeparator(canShowSeparator: Bool, forContentViewAtIndex index: Int) {
        let item = items[index]
        if canShowSeparator
            && (index < items.endIndex.predecessor())
            && item.separatorView == nil {
            if let separatorView = createSeparatorView() {
                item.separatorView = separatorView
                stackView.insertArrangedSubview(separatorView, atIndex: index.successor())
            }
        } else if let separatorView = item.separatorView where !canShowSeparator {
            stackView.removeArrangedSubview(separatorView)
            item.separatorView = nil
        }
    }
    
    private func relayoutContent(didUpdateContent: Bool) {
        let canShowSeparatorConfig: [Bool]?
        if didUpdateContent {
            canShowSeparatorConfig = nil
        } else {
            canShowSeparatorConfig = items.map { $0.canShowSeparator }
        }
        let canShowSeparator: (Int -> Bool) = { index in
            if let canShowSeparatorConfig = canShowSeparatorConfig {
                return canShowSeparatorConfig[index]
            } else {
                return true
            }
        }
        items.removeAll(keepCapacity: true)
        stackView.removeAllArrangedSubviews()
        let contentViews = _contentViews
        _contentViews.removeAll(keepCapacity: true)
        for (index, contentView) in contentViews.enumerate() {
            addContentView(contentView, canShowSeparator: canShowSeparator(index))
        }
    }
    
    private func createSeparatorView() -> UIView? {
        guard let separatorViewFactory = separatorViewFactory else { return nil }
        return separatorViewFactory(stackView.axis)
    }
    
    // MARK: UIScrollViewDelegate
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        guard let backgroundViewTopConstraint = backgroundViewTopConstraint else { return }
        backgroundViewTopConstraint.constant = -max(-scrollView.contentOffset.y, 0)
    }
    
    // MARK: ContentContainerView
    
    private class Item {
        private let contentView: UIView
        private let canShowSeparator: Bool
        private var separatorView: UIView?
        
        init(contentView: UIView, canShowSeparator: Bool, separatorView: UIView?) {
            self.contentView = contentView
            self.canShowSeparator = canShowSeparator
            self.separatorView = separatorView
        }
    }
}

private func constructDefaultStackView() -> UIStackView {
    let stackView = UIStackView(frame: CGRectZero)
    stackView.axis = .Vertical
    return stackView
}
