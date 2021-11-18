library responsive_grid;

import 'package:flutter/widgets.dart';

//
// scaling
//

//double _scalingMargin = 5;
double _refWidth = 375;

double? _scalingFactor;
double? _width;

void initScaling(BuildContext context) {
  var mq = MediaQuery.of(context);
  _width = mq.size.width < mq.size.height ? mq.size.width : mq.size.height;
  _scalingFactor = _width! / _refWidth;

  print("width => $_width");
}

double scale(double dimension) {
  if (_width == null) {
    throw Exception("You must call init() before any use of scale()");
  }
  //
  return dimension * _scalingFactor!;
}

//
// responsive grid layout
//

enum _GridTier { xs, sm, md, lg, xl }

_GridTier _currentSize(BuildContext context) {
  MediaQueryData mediaQueryData = MediaQuery.of(context);
  double width = mediaQueryData.size.width;

//  print(
//      "INFO orientation: ${mediaQueryData.orientation} , width: ${mediaQueryData.size.width}, height: ${mediaQueryData.size.height}");

  if (width < 576) {
    return _GridTier.xs;
  } else if (width < 768) {
    return _GridTier.sm;
  } else if (width < 992) {
    return _GridTier.md;
  } else if (width < 1200) {
    return _GridTier.lg;
  } else {
    // width >= 1200
    return _GridTier.xl;
  }
}

class ResponsiveGridRow extends StatelessWidget {
  final List<ResponsiveGridCol> children;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final int rowSegments;
  final double? height;
  final double? width;
  final BoxDecoration? decoration;
  final bool shrinkChildren;
  final BoxConstraints? constraints;
  final bool returnExpanded;

  ResponsiveGridRow(
      {required this.children,
      this.crossAxisAlignment = CrossAxisAlignment.start,
      this.mainAxisAlignment = MainAxisAlignment.start,
      this.rowSegments = 12,
      this.height,
      this.width,
      this.decoration,
      this.shrinkChildren = false,
      this.constraints,
      this.returnExpanded = false});

  @override
  Widget build(BuildContext context) {
    final rows = <Row>[];

    int accumulatedWidth = 0;
    var cols = <Widget>[];

    children.forEach((col) {
      var colWidth = col.currentConfig(context) ?? 1;
      //
      if (accumulatedWidth + colWidth > rowSegments) {
        if (accumulatedWidth < rowSegments && this.shrinkChildren) {
          cols.add(Spacer(
            flex: rowSegments - accumulatedWidth,
          ));
        }
        rows.add(Row(
          children: cols,
        ));
        // clear
        cols = <Widget>[];
        accumulatedWidth = 0;
      }
      //
      cols.add(col);
      accumulatedWidth += colWidth;
    });

    if (accumulatedWidth >= 0) {
      if (accumulatedWidth < rowSegments && this.shrinkChildren) {
        cols.add(Spacer(
          flex: rowSegments - accumulatedWidth,
        ));
      }
      rows.add(Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: this.mainAxisAlignment,
        crossAxisAlignment: this.crossAxisAlignment,
        children: cols,
      ));
    }

    return Container(
      height: this.height,
      width: this.width,
      decoration: this.decoration,
      constraints: this.constraints,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: rows,
      ),
      //children: rows,
    );
  }
}

class ResponsiveGridCol extends Container {
  final _config = <int?>[]..length = 5;
  final Widget child;
  final Alignment? alignment;
  final returnExpanded;
  final BoxDecoration? decoration;

  ResponsiveGridCol({
    int xs = 12,
    int? sm,
    int? md,
    int? lg,
    int? xl,
    required this.child,
    this.alignment,
    this.returnExpanded = false,
    this.decoration,
  }) : super() {
    _config[_GridTier.xs.index] = xs;
    _config[_GridTier.sm.index] = sm ?? _config[_GridTier.xs.index];
    _config[_GridTier.md.index] = md ?? _config[_GridTier.sm.index];
    _config[_GridTier.lg.index] = lg ?? _config[_GridTier.md.index];
    _config[_GridTier.xl.index] = xl ?? _config[_GridTier.lg.index];
  }

  int? currentConfig(BuildContext context) {
    return _config[_currentSize(context).index];
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: currentConfig(context) ?? 1,
      child: this.returnExpanded
          ? child
          : Container(
              alignment: this.alignment,
              decoration: this.decoration,
              child: child),
    );
  }
}

class StaggeredResponsiveGridRow extends StatelessWidget {
  final List<StaggeredResponsiveGridCol> children;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final int rowSegments;
  final double? height;
  final double? width;
  final BoxDecoration? decoration;
  final bool shrinkChildren;
  final BoxConstraints? constraints;
  final bool returnExpanded;

  StaggeredResponsiveGridRow(
      {required this.children,
      this.crossAxisAlignment = CrossAxisAlignment.start,
      this.mainAxisAlignment = MainAxisAlignment.start,
      this.rowSegments = 12,
      this.height,
      this.width,
      this.decoration,
      this.shrinkChildren = false,
      this.constraints,
      this.returnExpanded = false});

  @override
  Widget build(BuildContext context) {
    final rows = <Row>[];
    final rowKeys = <GlobalKey>[];
    int accumulatedWidth = 0;
    var cols = <Widget>[];

    children.forEach((col) {
      var colWidth = col.currentConfig(context) ?? 1;
      //
      if (accumulatedWidth + colWidth > rowSegments) {
        // if (accumulatedWidth < rowSegments && this.shrinkChildren) {
        //   cols.add(Spacer(
        //     flex: rowSegments - accumulatedWidth,
        //   ));
        // }
        rowKeys.add(GlobalKey());
        rows.add(Row(
          key: rowKeys.last,
          children: cols,
        ));
        // clear
        cols = <Widget>[];
        accumulatedWidth = 0;
      }
      //
      if (rows.length > 0) {
        var rowAboveHeight = rowKeys.last.currentContext?.size?.height ?? 0;
        var corresPondingChild = rows.last.children[cols.length];
        double colAboveHeight;
        if (corresPondingChild.runtimeType.toString() ==
            'StaggeredResponsiveGridCol') {
          colAboveHeight = (corresPondingChild as StaggeredResponsiveGridCol)
                  .colKey
                  .currentContext
                  ?.findRenderObject()
                  ?.paintBounds
                  .size
                  .height ??
              0;
        } else {
          colAboveHeight = ((corresPondingChild as Container).child
                      as StaggeredResponsiveGridCol)
                  .colKey
                  .currentContext
                  ?.findRenderObject()
                  ?.paintBounds
                  .size
                  .height ??
              0;
        }
        cols.add(Container(
          transform: Matrix4.translationValues(
              0.0, (colAboveHeight - rowAboveHeight), 0.0),
          child: col,
        ));
      } else {
        cols.add(col);
      }
      accumulatedWidth += colWidth;
    });

    if (accumulatedWidth >= 0) {
      // if (accumulatedWidth < rowSegments && this.shrinkChildren){
      //   cols.add(Spacer(
      //     flex: rowSegments - accumulatedWidth,
      //   ));
      // }
      rows.add(Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: this.mainAxisAlignment,
        crossAxisAlignment: this.crossAxisAlignment,
        children: cols,
      ));
    }

    return Container(
      height: this.height,
      width: this.width,
      decoration: this.decoration,
      constraints: this.constraints,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: rows,
      ),
      //children: rows,
    );
  }
}

class StaggeredResponsiveGridCol extends Container {
  final _config = <int?>[]..length = 5;
  final Widget child;
  final Alignment? alignment;
  final returnExpanded;
  final GlobalKey colKey = GlobalKey();

  StaggeredResponsiveGridCol({
    int xs = 12,
    int? sm,
    int? md,
    int? lg,
    int? xl,
    required this.child,
    this.alignment,
    this.returnExpanded = false,
  }) : super() {
    _config[_GridTier.xs.index] = xs;
    _config[_GridTier.sm.index] = sm ?? _config[_GridTier.xs.index];
    _config[_GridTier.md.index] = md ?? _config[_GridTier.sm.index];
    _config[_GridTier.lg.index] = lg ?? _config[_GridTier.md.index];
    _config[_GridTier.xl.index] = xl ?? _config[_GridTier.lg.index];
  }

  int? currentConfig(BuildContext context) {
    return _config[_currentSize(context).index];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: this.colKey,
      //flex: currentConfig(context) ?? 1,
      child: this.returnExpanded
          ? child
          : Container(alignment: this.alignment, child: child),
    );
  }
}

//
// responsive grid list
//

class ResponsiveGridList extends StatelessWidget {
  final double desiredItemWidth, minSpacing;
  final List<Widget> children;
  final bool squareCells, scroll;
  final MainAxisAlignment rowMainAxisAlignment;

  ResponsiveGridList({
    required this.desiredItemWidth,
    this.minSpacing = 1,
    this.squareCells = false,
    this.scroll = true,
    required this.children,
    this.rowMainAxisAlignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (children.length == 0) return Container();

        double width = constraints.maxWidth;

        double N = (width - minSpacing) / (desiredItemWidth + minSpacing);

        int n;
        double spacing, itemWidth;

        if (N % 1 == 0) {
          n = N.floor();
          spacing = minSpacing;
          itemWidth = desiredItemWidth;
        } else {
          n = N.floor();

          double dw =
              width - (n * (desiredItemWidth + minSpacing) + minSpacing);

          itemWidth = desiredItemWidth +
              (dw / n) * (desiredItemWidth / (desiredItemWidth + minSpacing));

          spacing = (width - itemWidth * n) / (n + 1);
        }

        if (scroll) {
          return ListView.builder(
              itemCount: (children.length / n).ceil() * 2 - 1,
              itemBuilder: (context, index) {
                //if (index * n >= children.length) return null;
                //separator
                if (index % 2 == 1) {
                  return SizedBox(
                    height: minSpacing,
                  );
                }
                //item
                final rowChildren = <Widget>[];
                index = index ~/ 2;
                for (int i = index * n; i < (index + 1) * n; i++) {
                  if (i >= children.length) break;
                  rowChildren.add(children[i]);
                }
                return _ResponsiveGridListItem(
                  mainAxisAlignment: this.rowMainAxisAlignment,
                  itemWidth: itemWidth,
                  spacing: spacing,
                  squareCells: squareCells,
                  children: rowChildren,
                );
              });
        } else {
          final rows = <Widget>[];
          rows.add(SizedBox(
            height: minSpacing,
          ));
          //
          for (int j = 0; j < (children.length / n).ceil(); j++) {
            final rowChildren = <Widget>[];
            //
            for (int i = j * n; i < (j + 1) * n; i++) {
              if (i >= children.length) break;
              rowChildren.add(children[i]);
            }
            //
            rows.add(_ResponsiveGridListItem(
              mainAxisAlignment: this.rowMainAxisAlignment,
              itemWidth: itemWidth,
              spacing: spacing,
              squareCells: squareCells,
              children: rowChildren,
            ));

            rows.add(SizedBox(
              height: minSpacing,
            ));
          }

          return Column(
            children: rows,
          );
        }
      },
    );
  }
}

class _ResponsiveGridListItem extends StatelessWidget {
  final double spacing, itemWidth;
  final List<Widget> children;
  final bool squareCells;
  final MainAxisAlignment mainAxisAlignment;

  _ResponsiveGridListItem({
    required this.itemWidth,
    required this.spacing,
    required this.squareCells,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: this.mainAxisAlignment,
      children: _buildChildren(),
    );
  }

  List<Widget> _buildChildren() {
    final list = <Widget>[];

    list.add(SizedBox(
      width: spacing,
    ));

    children.forEach((child) {
      list.add(SizedBox(
        width: itemWidth,
        height: squareCells ? itemWidth : null,
        child: child,
      ));
      list.add(SizedBox(
        width: spacing,
      ));
    });

    return list;
  }
}
