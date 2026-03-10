import 'package:flutter/material.dart';

/// Breakpoints para responsividade
class AppBreakpoints {
  static const double tablet = 768;
  static const double desktop = 1024;
}

/// Widget que centraliza e limita o conteúdo em telas maiores.
/// Em telas de desktop (>768px), aplica 20% de padding lateral.
class ResponsiveBody extends StatelessWidget {
  final Widget child;

  const ResponsiveBody({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width > AppBreakpoints.tablet) {
          final horizontalPadding = width * 0.20;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: child,
          );
        }
        return child;
      },
    );
  }
}

/// Wrapper do GridView que ajusta o número de colunas por tamanho de tela.
/// Mobile: 2, Tablet: 3, Desktop: 4
class ResponsiveGrid extends StatelessWidget {
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double childAspectRatio;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  const ResponsiveGrid({
    super.key,
    this.mobileColumns = 2,
    this.tabletColumns = 3,
    this.desktopColumns = 4,
    this.childAspectRatio = 0.95,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int columns;
        if (width > AppBreakpoints.desktop) {
          columns = desktopColumns;
        } else if (width > AppBreakpoints.tablet) {
          columns = tabletColumns;
        } else {
          columns = mobileColumns;
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        );
      },
    );
  }
}
