import Foundation
import Display
import ComponentFlow
import SwiftSignalKit
import Postbox
import TelegramCore
import AccountContext
import TelegramPresentationData
import UIKit
import WebPBinding

public final class ReactionButtonComponent: Component {
    public struct ViewTag: Equatable {
        public var value: String
        
        public init(value: String) {
            self.value = value
        }
    }
    
    public struct Reaction: Equatable {
        public var value: String
        public var iconFile: TelegramMediaFile?
        
        public init(value: String, iconFile: TelegramMediaFile?) {
            self.value = value
            self.iconFile = iconFile
        }
        
        public static func ==(lhs: Reaction, rhs: Reaction) -> Bool {
            if lhs.value != rhs.value {
                return false
            }
            if lhs.iconFile?.fileId != rhs.iconFile?.fileId {
                return false
            }
            return true
        }
    }
    
    public struct Colors: Equatable {
        public var background: UInt32
        public var foreground: UInt32
        public var stroke: UInt32
        
        public init(
            background: UInt32,
            foreground: UInt32,
            stroke: UInt32
        ) {
            self.background = background
            self.foreground = foreground
            self.stroke = stroke
        }
    }
    
    public let context: AccountContext
    public let colors: Colors
    public let reaction: Reaction
    public let count: Int
    public let isSelected: Bool
    public let action: (String) -> Void

    public init(
        context: AccountContext,
        colors: Colors,
        reaction: Reaction,
        count: Int,
        isSelected: Bool,
        action: @escaping (String) -> Void
    ) {
        self.context = context
        self.colors = colors
        self.reaction = reaction
        self.count = count
        self.isSelected = isSelected
        self.action = action
    }

    public static func ==(lhs: ReactionButtonComponent, rhs: ReactionButtonComponent) -> Bool {
        if lhs.context !== rhs.context {
            return false
        }
        if lhs.colors != rhs.colors {
            return false
        }
        if lhs.reaction != rhs.reaction {
            return false
        }
        if lhs.count != rhs.count {
            return false
        }
        if lhs.isSelected != rhs.isSelected {
            return false
        }
        return true
    }

    public final class View: UIButton, ComponentTaggedView {
        public let iconView: UIImageView
        private let textView: ComponentHostView<Empty>
        
        private var currentComponent: ReactionButtonComponent?
        
        private let iconImageDisposable = MetaDisposable()
        
        init() {
            self.iconView = UIImageView()
            self.iconView.isUserInteractionEnabled = false
            
            self.textView = ComponentHostView<Empty>()
            self.textView.isUserInteractionEnabled = false
            
            super.init(frame: CGRect())
            
            self.addSubview(self.iconView)
            self.addSubview(self.textView)
            
            self.addTarget(self, action: #selector(self.pressed), for: .touchUpInside)
        }

        required init?(coder aDecoder: NSCoder) {
            preconditionFailure()
        }
        
        deinit {
            self.iconImageDisposable.dispose()
        }
        
        @objc private func pressed() {
            guard let currentComponent = self.currentComponent else {
                return
            }
            currentComponent.action(currentComponent.reaction.value)
        }
        
        public func matches(tag: Any) -> Bool {
            guard let tag = tag as? ViewTag else {
                return false
            }
            guard let currentComponent = self.currentComponent else {
                return false
            }
            if currentComponent.reaction.value == tag.value {
                return true
            }
            return false
        }

        func update(component: ReactionButtonComponent, availableSize: CGSize, environment: Environment<Empty>, transition: Transition) -> CGSize {
            let sideInsets: CGFloat = 10.0
            let height: CGFloat = 30.0
            let spacing: CGFloat = 2.0
            
            let defaultImageSize = CGSize(width: 20.0, height: 20.0)
            
            let imageSize: CGSize
            if self.currentComponent?.reaction != component.reaction {
                if let file = component.reaction.iconFile {
                    self.iconImageDisposable.set((component.context.account.postbox.mediaBox.resourceData(file.resource)
                    |> deliverOnMainQueue).start(next: { [weak self] data in
                        guard let strongSelf = self else {
                            return
                        }
                        
                        if data.complete, let dataValue = try? Data(contentsOf: URL(fileURLWithPath: data.path)) {
                            if let image = WebP.convert(fromWebP: dataValue) {
                                strongSelf.iconView.image = image
                            }
                        }
                    }))
                    imageSize = file.dimensions?.cgSize.aspectFitted(defaultImageSize) ?? defaultImageSize
                } else {
                    imageSize = defaultImageSize
                }
            } else {
                imageSize = self.iconView.bounds.size
            }
            
            self.iconView.frame = CGRect(origin: CGPoint(x: sideInsets, y: floorToScreenPixels((height - imageSize.height) / 2.0)), size: imageSize)
            
            let textSize: CGSize
            if self.currentComponent?.count != component.count || self.currentComponent?.colors != component.colors {
                textSize = self.textView.update(
                    transition: .immediate,
                    component: AnyComponent(Text(
                        text: "\(component.count)",
                        font: Font.regular(13.0),
                        color: UIColor(argb: component.colors.foreground)
                    )),
                    environment: {},
                    containerSize: CGSize(width: 100.0, height: 100.0)
                )
            } else {
                textSize = self.textView.bounds.size
            }
            
            if self.currentComponent?.colors != component.colors {
                self.backgroundColor = UIColor(argb: component.colors.background)
            }
            
            if self.currentComponent?.colors != component.colors || self.currentComponent?.isSelected != component.isSelected {
                if component.isSelected {
                    self.layer.borderColor = UIColor(argb: component.colors.stroke).cgColor
                    self.layer.borderWidth = 1.5
                } else {
                    self.layer.borderColor = nil
                    self.layer.borderWidth = 0.0
                }
            }
            
            self.layer.cornerRadius = height / 2.0
            
            self.textView.frame = CGRect(origin: CGPoint(x: sideInsets + imageSize.width + spacing, y: floorToScreenPixels((height - textSize.height) / 2.0)), size: textSize)
            
            self.currentComponent = component
            
            return CGSize(width: imageSize.width + spacing + textSize.width + sideInsets * 2.0, height: height)
        }
    }

    public func makeView() -> View {
        return View()
    }

    public func update(view: View, availableSize: CGSize, environment: Environment<Empty>, transition: Transition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, environment: environment, transition: transition)
    }
}

public final class ReactionButtonsLayoutContainer {
    public struct Reaction {
        public var reaction: ReactionButtonComponent.Reaction
        public var count: Int
        public var isSelected: Bool
        
        public init(
            reaction: ReactionButtonComponent.Reaction,
            count: Int,
            isSelected: Bool
        ) {
            self.reaction = reaction
            self.count = count
            self.isSelected = isSelected
        }
    }
    
    public struct Result {
        public struct Item {
            public var view: ComponentHostView<Empty>
            public var size: CGSize
        }
        
        public var items: [Item]
        public var removedViews: [ComponentHostView<Empty>]
    }
    
    public private(set) var buttons: [String: ComponentHostView<Empty>] = [:]
    
    public init() {
    }
    
    public func update(
        context: AccountContext,
        action: @escaping (String) -> Void,
        reactions: [Reaction],
        colors: ReactionButtonComponent.Colors,
        constrainedWidth: CGFloat,
        transition: Transition
    ) -> Result {
        var items: [Result.Item] = []
        var removedViews: [ComponentHostView<Empty>] = []
        
        var validIds = Set<String>()
        for reaction in reactions {
            validIds.insert(reaction.reaction.value)
            
            let view: ComponentHostView<Empty>
            var itemTransition = transition
            if let current = self.buttons[reaction.reaction.value] {
                itemTransition = .immediate
                view = current
            } else {
                view = ComponentHostView<Empty>()
                self.buttons[reaction.reaction.value] = view
            }
            let itemSize = view.update(
                transition: itemTransition,
                component: AnyComponent(ReactionButtonComponent(
                    context: context,
                    colors: colors,
                    reaction: reaction.reaction,
                    count: reaction.count,
                    isSelected: reaction.isSelected,
                    action: action
                )),
                environment: {},
                containerSize: CGSize(width: constrainedWidth, height: 1000.0)
            )
            items.append(Result.Item(
                view: view,
                size: itemSize
            ))
        }
        
        var removeIds: [String] = []
        for (id, view) in self.buttons {
            if !validIds.contains(id) {
                removeIds.append(id)
                removedViews.append(view)
            }
        }
        for id in removeIds {
            self.buttons.removeValue(forKey: id)
        }
        
        return Result(
            items: items,
            removedViews: removedViews
        )
    }
}
