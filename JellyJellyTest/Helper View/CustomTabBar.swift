//
//  CustomTabBar.swift
//

import UIKit

@IBDesignable
class CustomTabBar: UITabBar {

    private var shapeLayer: CAShapeLayer?

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.addShape()
    }

    private func addShape() {
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = createPath()

        shapeLayer.strokeColor = UIColor.lightGray.cgColor
        shapeLayer.fillColor = UIColor.white.cgColor
        shapeLayer.lineWidth = 1.0

        shapeLayer.shadowOffset = CGSize(width: 0, height: 0)
        shapeLayer.shadowRadius = 10
        shapeLayer.shadowColor = UIColor.gray.cgColor
        shapeLayer.shadowOpacity = 0.3

        self.shapeLayer?.removeFromSuperlayer()
        self.layer.insertSublayer(shapeLayer, at: 0)
        self.shapeLayer = shapeLayer
    }

    private func createPath() -> CGPath {
        let height: CGFloat = 37.0
        let centerWidth = self.frame.width / 2
        let path = UIBezierPath()

        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: centerWidth - height * 2, y: 0))

        path.addCurve(to: CGPoint(x: centerWidth, y: height),
                      controlPoint1: CGPoint(x: centerWidth - 30, y: 0),
                      controlPoint2: CGPoint(x: centerWidth - 35, y: height))

        path.addCurve(to: CGPoint(x: centerWidth + height * 2, y: 0),
                      controlPoint1: CGPoint(x: centerWidth + 35, y: height),
                      controlPoint2: CGPoint(x: centerWidth + 30, y: 0))

        path.addLine(to: CGPoint(x: self.frame.width, y: 0))
        path.addLine(to: CGPoint(x: self.frame.width, y: self.frame.height))
        path.addLine(to: CGPoint(x: 0, y: self.frame.height))
        path.close()

        return path.cgPath
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !clipsToBounds, !isHidden, alpha > 0 else { return nil }

        for subview in subviews.reversed() {
            let subPoint = subview.convert(point, from: self)
            if let result = subview.hitTest(subPoint, with: event) {
                return result
            }
        }
        return nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.shapeLayer?.removeFromSuperlayer()
        self.addShape()
    }
}
