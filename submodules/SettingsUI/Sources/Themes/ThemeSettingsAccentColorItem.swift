import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramCore
import SyncCore
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import PresentationDataUtils

private func generateSwatchImage(theme: PresentationTheme, color: PresentationThemeAccentColor, bubbles: (UIColor, UIColor?)?, selected: Bool, more: Bool) -> UIImage? {
    return generateImage(CGSize(width: 40.0, height: 40.0), rotatedContext: { size, context in
        let bounds = CGRect(origin: CGPoint(), size: size)
        context.clear(bounds)
        
        let fillColor = color.color
        var strokeColor = color.baseColor.color
        if strokeColor == .clear {
            strokeColor = fillColor
        }
        if strokeColor.distance(to: theme.list.itemBlocksBackgroundColor) < 200 {
            if strokeColor.distance(to: UIColor.white) < 200 {
                strokeColor = UIColor(rgb: 0x999999)
            } else {
                strokeColor = theme.list.controlSecondaryColor
            }
        }
        
        context.setFillColor(fillColor.cgColor)
        context.setStrokeColor(strokeColor.cgColor)
        context.setLineWidth(2.0)
        
        if selected {
            context.saveGState()
            context.addEllipse(in: bounds.insetBy(dx: 4.0, dy: 4.0))
            context.clip()
    
            if let colors = bubbles {
                var colors: (UIColor, UIColor) = (colors.0, colors.1 ?? colors.0)
                
                let gradientColors = [colors.0.cgColor, colors.1.cgColor] as CFArray
                var locations: [CGFloat] = [0.0, 1.0]
                let colorSpace = CGColorSpaceCreateDeviceRGB()
                let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: &locations)!
                
                context.drawLinearGradient(gradient, start: CGPoint(x: 0.0, y: 0.0), end: CGPoint(x: 0.0, y: size.height), options: CGGradientDrawingOptions())
                
                context.fill(CGRect(x: 0.0, y: 0.0, width: size.width / 2.0, height: size.height))
            } else {
                context.fill(bounds)
            }
            
            context.restoreGState()
            context.strokeEllipse(in: bounds.insetBy(dx: 1.0, dy: 1.0))
            
            if more {
                context.setFillColor(UIColor.white.cgColor)
                let dotSize = CGSize(width: 4.0, height: 4.0)
                context.fillEllipse(in: CGRect(origin: CGPoint(x: 11.0, y: 18.0), size: dotSize))
                context.fillEllipse(in: CGRect(origin: CGPoint(x: 18.0, y: 18.0), size: dotSize))
                context.fillEllipse(in: CGRect(origin: CGPoint(x: 25.0, y: 18.0), size: dotSize))
            }
        } else {
            context.saveGState()
            context.addEllipse(in: bounds)
            context.clip()
            
            if let colors = bubbles {
                var colors: (UIColor, UIColor) = (colors.0, colors.1 ?? colors.0)
                
                let gradientColors = [colors.0.cgColor, colors.1.cgColor] as CFArray
                var locations: [CGFloat] = [0.0, 1.0]
                let colorSpace = CGColorSpaceCreateDeviceRGB()
                let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: &locations)!
                
                context.drawLinearGradient(gradient, start: CGPoint(x: 0.0, y: 0.0), end: CGPoint(x: 0.0, y: size.height), options: CGGradientDrawingOptions())
                
                context.fill(CGRect(x: 0.0, y: 0.0, width: size.width / 2.0, height: size.height))
            } else {
                context.fill(bounds)
            }
            
            context.restoreGState()
        }
    })?.stretchableImage(withLeftCapWidth: 15, topCapHeight: 15)
}

private func generateCustomSwatchImage() -> UIImage? {
    return generateImage(CGSize(width: 42.0, height: 42.0), rotatedContext: { size, context in
        let bounds = CGRect(origin: CGPoint(), size: size)
        context.clear(bounds)
        
        let dotSize = CGSize(width: 10.0, height: 10.0)
        
        context.setFillColor(UIColor(rgb: 0xd33213).cgColor)
        context.fillEllipse(in: CGRect(origin: CGPoint(x: 14.0, y: 16.0), size: dotSize))
        
        context.setFillColor(UIColor(rgb: 0xf08200).cgColor)
        context.fillEllipse(in: CGRect(origin: CGPoint(x: 14.0, y: 0.0), size: dotSize))
        
        context.setFillColor(UIColor(rgb: 0xedb400).cgColor)
        context.fillEllipse(in: CGRect(origin: CGPoint(x: 28.0, y: 8.0), size: dotSize))
        
        context.setFillColor(UIColor(rgb: 0x70bb23).cgColor)
        context.fillEllipse(in: CGRect(origin: CGPoint(x: 28.0, y: 24.0), size: dotSize))
        
        context.setFillColor(UIColor(rgb: 0x5396fa).cgColor)
        context.fillEllipse(in: CGRect(origin: CGPoint(x: 14.0, y: 32.0), size: dotSize))
        
        context.setFillColor(UIColor(rgb: 0x9472ee).cgColor)
        context.fillEllipse(in: CGRect(origin: CGPoint(x: 0.0, y: 24.0), size: dotSize))
        
        context.setFillColor(UIColor(rgb: 0xeb6ca4).cgColor)
        context.fillEllipse(in: CGRect(origin: CGPoint(x: 0.0, y: 8.0), size: dotSize))
    })
}

enum ThemeSettingsAccentColor {
    case `default`
    case color(PresentationThemeBaseColor)
}

class ThemeSettingsAccentColorItem: ListViewItem, ItemListItem {
    var sectionId: ItemListSectionId
    
    let theme: PresentationTheme
    let colors: [ThemeSettingsAccentColor]
    let currentColor: PresentationThemeAccentColor?
    let updated: (PresentationThemeAccentColor?) -> Void
    let openColorPicker: () -> Void
    let tag: ItemListItemTag?
    
    init(theme: PresentationTheme, sectionId: ItemListSectionId, colors: [ThemeSettingsAccentColor], currentColor: PresentationThemeAccentColor?, updated: @escaping (PresentationThemeAccentColor?) -> Void, openColorPicker: @escaping () -> Void, tag: ItemListItemTag? = nil) {
        self.theme = theme
        self.colors = colors
        self.currentColor = currentColor
        self.updated = updated
        self.openColorPicker = openColorPicker
        self.tag = tag
        self.sectionId = sectionId
    }
    
    func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        async {
            let node = ThemeSettingsAccentColorItemNode()
            let (layout, apply) = node.asyncLayout()(self, params, itemListNeighbors(item: self, topItem: previousItem as? ItemListItem, bottomItem: nextItem as? ItemListItem))
            
            node.contentSize = layout.contentSize
            node.insets = layout.insets
            
            Queue.mainQueue().async {
                completion(node, {
                    return (nil, { _ in apply() })
                })
            }
        }
    }
    
    func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping (ListViewItemApply) -> Void) -> Void) {
        Queue.mainQueue().async {
            if let nodeValue = node() as? ThemeSettingsAccentColorItemNode {
                let makeLayout = nodeValue.asyncLayout()
                
                async {
                    let (layout, apply) = makeLayout(self, params, itemListNeighbors(item: self, topItem: previousItem as? ItemListItem, bottomItem: nextItem as? ItemListItem))
                    Queue.mainQueue().async {
                        completion(layout, { _ in
                            apply()
                        })
                    }
                }
            }
        }
    }
}

private final class ThemeSettingsAccentColorNode : ASDisplayNode {
    private let iconNode: ASImageNode
    private var action: (() -> Void)?
    
    override init() {
        self.iconNode = ASImageNode()
        self.iconNode.frame = CGRect(origin: CGPoint(), size: CGSize(width: 62.0, height: 62.0))
        self.iconNode.isLayerBacked = true
        
        super.init()
        
        self.addSubnode(self.iconNode)
    }
    
    func setup(theme: PresentationTheme, color: PresentationThemeAccentColor, bubbles: (UIColor, UIColor?)?, selected: Bool, more: Bool, action: @escaping () -> Void) {
        self.iconNode.image = generateSwatchImage(theme: theme, color: color, bubbles: bubbles, selected: selected, more: more)
        self.action = {
            action()
        }
    }
    
    override func didLoad() {
        super.didLoad()
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapGesture(_:))))
    }
    
    @objc func tapGesture(_ recognizer: UITapGestureRecognizer) {
        if case .ended = recognizer.state {
            self.action?()
        }
    }
    
    override func layout() {
        super.layout()

        self.iconNode.frame = self.bounds
    }
}


private let textFont = Font.regular(11.0)
private let itemSize = Font.regular(11.0)

class ThemeSettingsAccentColorItemNode: ListViewItemNode, ItemListItemNode {
    private let backgroundNode: ASDisplayNode
    private let topStripeNode: ASDisplayNode
    private let bottomStripeNode: ASDisplayNode
    private let maskNode: ASImageNode
    
    private let scrollNode: ASScrollNode
    private var colorNodes: [ThemeSettingsAccentColorNode] = []
    private let customNode: HighlightableButtonNode
    
    private var item: ThemeSettingsAccentColorItem?
    private var layoutParams: ListViewItemLayoutParams?
    
    var tag: ItemListItemTag? {
        return self.item?.tag
    }
    
    init() {
        self.backgroundNode = ASDisplayNode()
        self.backgroundNode.isLayerBacked = true
        
        self.topStripeNode = ASDisplayNode()
        self.topStripeNode.isLayerBacked = true
        
        self.bottomStripeNode = ASDisplayNode()
        self.bottomStripeNode.isLayerBacked = true
        
        self.maskNode = ASImageNode()
        
        self.scrollNode = ASScrollNode()
        
        self.customNode = HighlightableButtonNode()
        
        super.init(layerBacked: false, dynamicBounce: false)

        self.customNode.setImage(generateCustomSwatchImage(), for: .normal)
        self.customNode.addTarget(self, action: #selector(customPressed), forControlEvents: .touchUpInside)
        
        self.addSubnode(self.scrollNode)
        self.scrollNode.addSubnode(self.customNode)
    }
    
    override func didLoad() {
        super.didLoad()
        self.scrollNode.view.disablesInteractiveTransitionGestureRecognizer = true
        self.scrollNode.view.showsHorizontalScrollIndicator = false
    }
    
    @objc func customPressed() {
        self.item?.openColorPicker()
    }
    
    private func scrollToNode(_ node: ThemeSettingsAccentColorNode, animated: Bool) {
        let bounds = self.scrollNode.view.bounds
        let frame = node.frame.insetBy(dx: -48.0, dy: 0.0)
        
        if frame.minX < bounds.minX || frame.maxX > bounds.maxX {
            self.scrollNode.view.scrollRectToVisible(frame, animated: animated)
        }
    }
    
    func asyncLayout() -> (_ item: ThemeSettingsAccentColorItem, _ params: ListViewItemLayoutParams, _ neighbors: ItemListNeighbors) -> (ListViewItemNodeLayout, () -> Void) {
        let currentItem = self.item
        
        return { item, params, neighbors in
            var themeUpdated = false
            if currentItem?.theme !== item.theme {
                themeUpdated = true
            }
            
            let contentSize: CGSize
            let insets: UIEdgeInsets
            let separatorHeight = UIScreenPixel
            
            contentSize = CGSize(width: params.width, height: 60.0)
            insets = itemListNeighborsGroupedInsets(neighbors)
            
            let layout = ListViewItemNodeLayout(contentSize: contentSize, insets: insets)
            let layoutSize = layout.size
            
            return (layout, { [weak self] in
                if let strongSelf = self {
                    strongSelf.item = item
                    strongSelf.layoutParams = params
                    
                    strongSelf.scrollNode.view.contentInset = UIEdgeInsets(top: 0.0, left: params.leftInset, bottom: 0.0, right: params.rightInset)
                    strongSelf.backgroundNode.backgroundColor = item.theme.list.itemBlocksBackgroundColor
                    strongSelf.topStripeNode.backgroundColor = item.theme.list.itemBlocksSeparatorColor
                    strongSelf.bottomStripeNode.backgroundColor = item.theme.list.itemBlocksSeparatorColor
                    
                    if strongSelf.backgroundNode.supernode == nil {
                        strongSelf.insertSubnode(strongSelf.backgroundNode, at: 0)
                    }
                    if strongSelf.topStripeNode.supernode == nil {
                        strongSelf.insertSubnode(strongSelf.topStripeNode, at: 1)
                    }
                    if strongSelf.bottomStripeNode.supernode == nil {
                        strongSelf.insertSubnode(strongSelf.bottomStripeNode, at: 2)
                    }
                    if strongSelf.maskNode.supernode == nil {
                        strongSelf.insertSubnode(strongSelf.maskNode, at: 3)
                    }
                    
                    let hasCorners = itemListHasRoundedBlockLayout(params)
                    var hasTopCorners = false
                    var hasBottomCorners = false
                    switch neighbors.top {
                        case .sameSection(false):
                            strongSelf.topStripeNode.isHidden = true
                        default:
                            hasTopCorners = true
                            strongSelf.topStripeNode.isHidden = hasCorners
                    }
                    let bottomStripeInset: CGFloat
                    let bottomStripeOffset: CGFloat
                    switch neighbors.bottom {
                        case .sameSection(false):
                            bottomStripeInset = params.leftInset + 16.0
                            bottomStripeOffset = -separatorHeight
                        default:
                            bottomStripeInset = 0.0
                            bottomStripeOffset = 0.0
                            hasBottomCorners = true
                            strongSelf.bottomStripeNode.isHidden = hasCorners
                    }
                    
                    strongSelf.maskNode.image = hasCorners ? PresentationResourcesItemList.cornersImage(item.theme, top: hasTopCorners, bottom: hasBottomCorners) : nil
                    
                    strongSelf.backgroundNode.frame = CGRect(origin: CGPoint(x: 0.0, y: -min(insets.top, separatorHeight)), size: CGSize(width: params.width, height: contentSize.height + min(insets.top, separatorHeight) + min(insets.bottom, separatorHeight)))
                    strongSelf.maskNode.frame = strongSelf.backgroundNode.frame.insetBy(dx: params.leftInset, dy: 0.0)
                    strongSelf.topStripeNode.frame = CGRect(origin: CGPoint(x: 0.0, y: -min(insets.top, separatorHeight)), size: CGSize(width: layoutSize.width, height: separatorHeight))
                    strongSelf.bottomStripeNode.frame = CGRect(origin: CGPoint(x: bottomStripeInset, y: contentSize.height + bottomStripeOffset), size: CGSize(width: layoutSize.width - bottomStripeInset, height: separatorHeight))
                    
                    strongSelf.scrollNode.frame = CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: layoutSize.width, height: layoutSize.height))
                    
                    let nodeInset: CGFloat = 15.0
                    let nodeSize = CGSize(width: 40.0, height: 40.0)
                    var nodeOffset = nodeInset
                    
                    var updated = false
                    var selectedNode: ThemeSettingsAccentColorNode?
                    
                    var i = 0
                    for color in item.colors {
                        let imageNode: ThemeSettingsAccentColorNode
                        if strongSelf.colorNodes.count > i {
                            imageNode = strongSelf.colorNodes[i]
                        } else {
                            imageNode = ThemeSettingsAccentColorNode()
                            strongSelf.colorNodes.append(imageNode)
                            strongSelf.scrollNode.addSubnode(imageNode)
                            updated = true
                        }
                        
                        let selected: Bool
                        var accentColor: PresentationThemeAccentColor
                        var itemColor: PresentationThemeAccentColor?
                        switch color {
                            case .default:
                                selected = item.currentColor == nil
                                accentColor = PresentationThemeAccentColor(baseColor: .blue, accentColor: 0x007ee5, bubbleColors: (0xe1ffc7, nil))
                            case let .color(color):
                                selected = item.currentColor?.baseColor == color
                                if let currentColor = item.currentColor, selected {
                                    accentColor = currentColor
                                } else {
                                    accentColor = PresentationThemeAccentColor(baseColor: color)
                                }
                                itemColor = accentColor
                        }
                    
                        if selected {
                            selectedNode = imageNode
                        }
                                          
                        imageNode.setup(theme: item.theme, color: accentColor, bubbles: accentColor.customBubbleColors, selected: selected, more: itemColor != nil, action: { [weak self, weak imageNode] in
                            if selected {
                                if itemColor != nil {
                                    item.openColorPicker()
                                }
                            } else {
                                item.updated(itemColor)
                            }
                            if let imageNode = imageNode {
                                self?.scrollToNode(imageNode, animated: true)
                            }
                        })
                        
                        imageNode.frame = CGRect(origin: CGPoint(x: nodeOffset, y: 10.0), size: nodeSize)
                        nodeOffset += nodeSize.width + 18.0
                        
                        i += 1
                    }
                    
                    strongSelf.customNode.frame = CGRect(origin: CGPoint(x: nodeOffset, y: 9.0), size: CGSize(width: 42.0, height: 42.0))
                    
                    for k in (i ..< strongSelf.colorNodes.count).reversed() {
                        let node = strongSelf.colorNodes[k]
                        strongSelf.colorNodes.remove(at: k)
                        node.removeFromSupernode()
                    }
                
                    let contentSize = CGSize(width: strongSelf.customNode.frame.maxX + nodeInset, height: strongSelf.scrollNode.frame.height)
                    if strongSelf.scrollNode.view.contentSize != contentSize {
                        strongSelf.scrollNode.view.contentSize = contentSize
                    }
                    
                    if updated, let selectedNode = selectedNode {
                        strongSelf.scrollToNode(selectedNode, animated: false)
                    }
                }
            })
        }
    }
    
    override func animateInsertion(_ currentTimestamp: Double, duration: Double, short: Bool) {
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.4)
    }
    
    override func animateRemoved(_ currentTimestamp: Double, duration: Double) {
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false)
    }
}

