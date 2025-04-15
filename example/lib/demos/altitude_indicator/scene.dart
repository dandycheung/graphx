/// copyright 2020, roipeker.
///
/// live demo:
/// http://roi-graphx-artificial-horizon.surge.sh/

/// Includes few comments and reiterative code, for the sake of quick
/// prototyping.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:graphx/graphx.dart';

class AltitudIndicatorScene extends GSprite {
  GSprite mainContainer = GSprite();

  /// inner circle.
  GSprite rotatorCircle = GSprite();
  GSprite? movable;

  double innerCircSeparation = 50.0;
  double outlineThickness1 = 18.0;
  double outlineThickness2 = 10.0;
  late double meterSize;
  final redColor = const Color(0xffDA5537);
  double valueMeterGap = 34.0;
  late double innerCircleSize;

  double get minStageSize => Math.min(stage!.stageWidth, stage!.stageHeight);

  @override
  void addedToStage() {
    meterSize = minStageSize;
    drawBackground();
    drawInnerCircle();
    addChild(mainContainer);

    var mainMask = GShape();
    var radius = meterSize / 2;
    mainMask.graphics
        .beginFill(Colors.red.withOpacity(.3))
        .drawCircle(0, 0, radius)
        .endFill();
    addChild(mainMask);
    mainContainer.mask = mainMask;

    /// center pivot in the current bounding box of scene.
    alignPivot();

    stage!.onResized.add(() {
      /// position the scene in the middle of screen.
      setPosition(stage!.stageWidth / 2, stage!.stageHeight / 2);

      /// scale % accordingly.
      scale = minStageSize / meterSize;
    });
  }

  Future<void> drawInnerCircle() async {
    innerCircleSize = meterSize -
        outlineThickness1 * 2 -
        outlineThickness2 * 2 +
        4 -
        innerCircSeparation * 2;

    var maskCircle = GShape()
      ..graphics
          .beginFill(Colors.red.withOpacity(.4))
          .drawCircle(0, 0, innerCircleSize / 2)
          .endFill();

    drawRotator();

    /// apply the circle mask.
    rotatorCircle.mask = maskCircle;

    mainContainer.addChild(rotatorCircle);

    /// if you dont add the mask, the Matrix transformation will not apply.
    /// and will work on local coordinates of the maskee.
    mainContainer.addChild(maskCircle);

    /// add the static plane reference.
    var plane = buildPlane();
    mainContainer.addChild(plane);

    createOutsideLines();

    /// create some movement for the airplane!
    stage!.onEnterFrame.add(onEnterFrame);
  }

  bool isPressed(LogicalKeyboardKey key) => stage!.keyboard.isPressed(key);

  int getDirY() {
    if (isPressed(LogicalKeyboardKey.arrowDown)) {
      return -1;
    } else if (isPressed(LogicalKeyboardKey.arrowUp)) {
      return 1;
    }
    return 0;
  }

  int getDirX() {
    if (isPressed(LogicalKeyboardKey.arrowLeft)) {
      return -1;
    } else if (isPressed(LogicalKeyboardKey.arrowRight)) {
      return 1;
    }
    return 0;
  }

  void onEnterFrame(double delta) {
    var dirY = getDirY();
    var dirX = getDirX();

    if (dirY != 0) {
      movable!.y += 1.2 * dirY;
    } else {
      movable!.y += (-movable!.y) / 20;
    }

    if (dirX != 0) {
      rotatorCircle.rotation += .03 * dirX;
      rotatorCircle.rotation = MathUtils.shortRotation(rotatorCircle.rotation);
    } else {
      rotatorCircle.rotation += (0 - rotatorCircle.rotation) / 18;
    }

    var maxRangeY = valueMeterGap * 2;
    if (movable!.y > maxRangeY) {
      movable!.y = maxRangeY;
    } else if (movable!.y < -maxRangeY) {
      movable!.y = -maxRangeY;
    }

//    rotatorCircle.rotation += .01;
  }

  GSprite? drawRotator() {
    /// background first.
    movable = GSprite();

    /// center pivot in the drawn object.
    rotatorCircle.alignPivot();

    var sky =
        buildBox(const Color(0xff3D84A9), innerCircleSize, innerCircleSize);
    var ground =
        buildBox(const Color(0xff493F42), innerCircleSize, innerCircleSize);
    var line = buildBox(kColorWhite, innerCircleSize, 2);

    sky.alignPivot(Alignment.bottomCenter);
    ground.alignPivot(Alignment.topCenter);
    line.alignPivot();

    movable!.addChild(sky);
    movable!.addChild(ground);
    movable!.addChild(line);

    /// another option to draw background.
//    var rotatorBackground = GShape();
//    var g = rotatorBackground.graphics;
//    g
//        .beginFill(0x3D84A9)
//        .drawRect(0, 0, innerCircleSize, innerCircleSize / 2)
//        .endFill()
////    and floor.
//        .beginFill(0x493F42)
//        .drawRect(0, innerCircleSize / 2, innerCircleSize, innerCircleSize / 2)
//        .endFill()
////    and middle line.
//        .lineStyle(2, 0xffffff)
//        .moveTo(0, innerCircleSize / 2)
//        .lineTo(innerCircleSize, innerCircleSize / 2)
//        .endFill();
//    movable.addChild(rotatorBackground);

    var elements = buildRotatorElements();
    movable!.addChild(elements);
    rotatorCircle.addChild(movable!);

    /// the red arrow should always stay in the same position...
    /// re-parent the element to the rotator circle.
    var arrow = elements.getChildByName('arrow')!;
    rotatorCircle.addChild(arrow);
    return movable;
  }

  GSprite buildRotatorElements() {
    var content = GSprite();
    var w = innerCircleSize;

    /// build arrow.
    var arrow = buildArrow(height: 30, color: redColor, linkThickness: 4);
    arrow.name = 'arrow';
    arrow.y = -w / 2 + 6; // + 6= compensate line miter joints.
    arrow.rotation = deg2rad(180);
    content.addChild(arrow);

    var lines = GSprite();
    content.addChild(lines);

    GText buildTextVal(int value) {
      var tf = GText(
        text: value.toString(),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );
      tf.validate();
      tf.scaleY = 1.2; // give some stretch.
      tf.alignPivot();
      return tf;
    }

    GSprite _addLine(int index) {
      var absoluteValue = index < 0 ? -index : index;
      var spr = GSprite();
      var tf1 = buildTextVal(absoluteValue * 10);
      var tf2 = buildTextVal(absoluteValue * 10);
      const textSepStep = 14.0;
      const minSep = 28.0;
      tf1.x = -textSepStep * absoluteValue - minSep;
      tf2.x = textSepStep * absoluteValue + minSep;

      final lineOffset = (tf1.textWidth / 2 + 6); // 6 is the gap

      spr.graphics
          .lineStyle(1.6, kColorWhite)
          .moveTo(tf1.x + lineOffset, 0)
          .lineTo(tf2.x - lineOffset, 0);

      var underlineY = valueMeterGap / 2;

      if (index > 0) {
        /// when drawing the bottom underlines ... draw them
        /// at the top of the text.
        underlineY *= -1;
      }

      const underlineW = 28.0;
      spr.graphics
          .moveTo(-underlineW / 2, underlineY)
          .lineTo(underlineW / 2, underlineY)
          .endFill();

      spr.addChild(tf1);
      spr.addChild(tf2);
      return spr;
    }

    for (var i = -2; i <= 2; ++i) {
      // dont draw the middle value.
      if (i == 0) continue;
      var line = _addLine(i);
      line.y = i * valueMeterGap.toDouble();
      lines.addChild(line);
    }

    return content;
  }

  GShape buildPlane() {
    var w = innerCircleSize - innerCircSeparation * 2;
    var lineSize = w / 3.5;
    var plane = GShape();
    final g = plane.graphics;
    g.lineStyle(6, redColor, true, StrokeCap.round, StrokeJoin.round);
    g.moveTo(0, 0).lineTo(lineSize, 0);

    /// semi circle.
    var arcCenterX = w / 2;
    var arcRadius = (w - lineSize * 2) / 2;
    g.arc(arcCenterX, 0, arcRadius, deg2rad(0), deg2rad(180));
    g.moveTo(w - lineSize, 0).lineTo(w, 0);
    g.endFill();

    g.beginFill(redColor).drawCircle(arcCenterX, 0, 4);

    /// align the GShape to the center.
    plane.alignPivot(Alignment.topCenter);

    /// compensate the offset bounds generated by line thickness and the
    /// center dot.
    plane.pivotY += 4;

    return plane;
  }

  void drawBackground() {
    var radius = meterSize / 2;
    var outlines = GShape();
    final g = outlines.graphics;
    g
        .lineStyle(outlineThickness1, const Color(0xff3B414B))
        .drawCircle(0, 0, radius - outlineThickness1 * .4);
    g
        .lineStyle(outlineThickness2, const Color(0xff1C2023))
        .drawCircle(0, 0, radius - outlineThickness1 - outlineThickness2 * .3);

    /// draw the floor.
    var skyFloor = GShape();
    skyFloor.graphics
        .beginFill(const Color(0xff5ABAEC))
        .drawRect(0, 0, meterSize, meterSize / 2);
    skyFloor.graphics
        .beginFill(const Color(0xff5E5351))
        .drawRect(0, meterSize / 2, meterSize, meterSize / 2);
    skyFloor.alignPivot();
    mainContainer.addChild(skyFloor);
    mainContainer.addChild(outlines);
  }

  void createOutsideLines() {
    var outsideLinesPicture = _createOutsideLinesPicture();

    var left = GShape();
    var right = GShape();
    left.graphics.drawPicture(outsideLinesPicture);
    right.graphics.drawPicture(outsideLinesPicture);

    /// flip horizontally.
    right.scaleX = -1;
    mainContainer.addChildAt(left, 1);
    mainContainer.addChildAt(right, 1);
  }

  Picture _createOutsideLinesPicture() {
    var linesContainer = GSprite();

    GShape _buildLine({
      double thickness = 3.0,
      required double rotationDegrees,
    }) {
      var line = GShape();
      line.graphics.lineStyle(thickness, kColorWhite);
      line.graphics.moveTo(0, 0);
      line.graphics.lineTo((innerCircleSize + innerCircSeparation) / 2, 0);
      line.pivotX = line.width;
      line.rotation = deg2rad(rotationDegrees);
      linesContainer.addChild(line);
      return line;
    }

    var bigStep = 90 / 3;
    var smallStep = bigStep / 3;
    var currentAngle = 0.0;

    /// center line.
    _buildLine(thickness: 5, rotationDegrees: 0);
    _buildLine(thickness: 5, rotationDegrees: currentAngle += bigStep);
    _buildLine(thickness: 5, rotationDegrees: currentAngle += bigStep);
    _buildLine(thickness: 2, rotationDegrees: currentAngle += smallStep);
    _buildLine(thickness: 2, rotationDegrees: currentAngle += smallStep);

    /// outside arrows are pushed away from the center by the radius.
    var arrow1 = buildArrow(height: innerCircSeparation * .9);
    arrow1.pivotY += innerCircleSize / 2;

    var arrow2 = buildArrow(height: innerCircSeparation / 2);
    arrow2.pivotY += innerCircleSize / 2;
    arrow2.rotation = -deg2rad(90 / 2);

    linesContainer.addChild(arrow1);
    linesContainer.addChild(arrow2);

    return linesContainer.createPicture();
  }

  GShape buildBox(Color color, double width, double height) {
    return GShape()
      ..graphics.beginFill(color).drawRect(0, 0, width, height).endFill();
  }

  GDisplayObject buildArrow({
    double height = 45.0,
    Color color = kColorWhite,
    double linkThickness = -1,
  }) {
    var widthRatio = 0.67;
    var w = height * widthRatio, h = height;
    var arrow = GShape();
    if (linkThickness < 0) {
      arrow.graphics.beginFill(color);
    } else {
      arrow.graphics.lineStyle(
        linkThickness,
        color,
        true,
        StrokeCap.square,
        StrokeJoin.miter,
        4,
      );
    }
    arrow.graphics.moveTo(0, 0).lineTo(w, 0).lineTo(w / 2, h).lineTo(0, 0);
    arrow.graphics.closePath();
    arrow.graphics.endFill();
    arrow.alignPivot(Alignment.bottomCenter);
    return arrow;
  }
}
