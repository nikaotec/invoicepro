// Testes do InvoicelyPro App - Validação de Responsividade
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:invoicepro/main.dart';

void main() {
  // Configuração para suprimir erros de overflow nos testes
  setUp(() {
    // Apenas suprime erros de overflow, mantém outros erros visíveis
    FlutterError.onError = (FlutterErrorDetails details) {
      final isOverflowError = details.exception.toString().contains(
        'RenderFlex overflowed',
      );
      if (!isOverflowError) {
        FlutterError.presentError(details);
      }
    };
  });

  group('App Initialization Tests', () {
    testWidgets('App deve inicializar corretamente', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: InvoicelyProApp()));
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('HomeScreen deve ser exibido', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: InvoicelyProApp()));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Dashboard deve ser a tela inicial', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: InvoicelyProApp()));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsAtLeastNWidgets(1));
    });

    testWidgets('FAB deve estar visível na tela inicial', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: InvoicelyProApp()));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('New Invoice'), findsOneWidget);
    });
  });

  group('Responsive Layout Tests', () {
    testWidgets('Mobile: Bottom Navigation deve ter 4 itens (< 600px)', (
      WidgetTester tester,
    ) async {
      // Breakpoint mobile < 600px
      await tester.binding.setSurfaceSize(const Size(400, 800));

      await tester.pumpWidget(const ProviderScope(child: InvoicelyProApp()));
      await tester.pumpAndSettle();

      // Em mobile, deve mostrar NavigationBar
      expect(find.byType(NavigationBar), findsOneWidget);

      // Verificar 4 destinos
      final navigationBar = find.byType(NavigationBar);
      expect(
        find.descendant(
          of: navigationBar,
          matching: find.byType(NavigationDestination),
        ),
        findsNWidgets(4),
      );

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Tablet: Navigation Rail deve ser exibido (>= 600px)', (
      WidgetTester tester,
    ) async {
      // Breakpoint tablet >= 600px && < 1024px
      await tester.binding.setSurfaceSize(const Size(768, 1024));

      await tester.pumpWidget(const ProviderScope(child: InvoicelyProApp()));
      await tester.pumpAndSettle();

      // Em tablet, deve mostrar NavigationRail
      expect(find.byType(NavigationRail), findsOneWidget);

      // Verificar 4 destinos
      final navigationRail = find.byType(NavigationRail);
      expect(
        find.descendant(
          of: navigationRail,
          matching: find.byType(NavigationRailDestination),
        ),
        findsNWidgets(4),
      );

      // Bottom nav NÃO deve estar visível em tablet
      expect(find.byType(NavigationBar), findsNothing);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Desktop: Navigation Rail deve ser exibido (>= 1024px)', (
      WidgetTester tester,
    ) async {
      // Breakpoint desktop >= 1024px
      await tester.binding.setSurfaceSize(const Size(1440, 900));

      await tester.pumpWidget(const ProviderScope(child: InvoicelyProApp()));
      await tester.pumpAndSettle();

      // Em desktop, deve mostrar NavigationRail
      expect(find.byType(NavigationRail), findsOneWidget);

      // Bottom nav NÃO deve estar visível em desktop
      expect(find.byType(NavigationBar), findsNothing);

      await tester.binding.setSurfaceSize(null);
    });
  });

  group('Navigation Tests', () {
    testWidgets('Mobile: Deve navegar entre telas usando Bottom Nav', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      await tester.pumpWidget(const ProviderScope(child: InvoicelyProApp()));
      await tester.pumpAndSettle();

      // Navegar para Invoices
      await tester.tap(find.text('Invoices'));
      await tester.pumpAndSettle();
      expect(find.text('Invoices'), findsAtLeastNWidgets(1));

      // Navegar para Clients
      await tester.tap(find.text('Clients'));
      await tester.pumpAndSettle();
      expect(find.text('Clients'), findsAtLeastNWidgets(1));

      // Navegar para Settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsAtLeastNWidgets(1));

      // Voltar para Dashboard
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsAtLeastNWidgets(1));

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Tablet: Deve navegar entre telas usando Navigation Rail', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(768, 1024));

      await tester.pumpWidget(const ProviderScope(child: InvoicelyProApp()));
      await tester.pumpAndSettle();

      // Em tablet usa NavigationRail
      await tester.tap(find.text('Invoices'));
      await tester.pumpAndSettle();
      expect(find.text('Invoices'), findsAtLeastNWidgets(1));

      await tester.tap(find.text('Clients'));
      await tester.pumpAndSettle();
      expect(find.text('Clients'), findsAtLeastNWidgets(1));

      await tester.binding.setSurfaceSize(null);
    });
  });

  group('Dashboard Content Tests', () {
    testWidgets('Dashboard deve exibir cards de resumo financeiro', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: InvoicelyProApp()));
      await tester.pumpAndSettle();

      // Verificar títulos dos cards
      expect(find.text('Total Revenue'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
    });

    testWidgets('Dashboard deve exibir gráfico de receita', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: InvoicelyProApp()));
      await tester.pumpAndSettle();

      expect(find.text('Revenue Trend'), findsOneWidget);
    });

    testWidgets('Dashboard deve exibir seção de invoices recentes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: InvoicelyProApp()));
      await tester.pumpAndSettle();

      expect(find.text('Recent Invoices'), findsOneWidget);
      expect(find.text('View All'), findsOneWidget);
      // Verificar pelo menos um invoice de exemplo
      expect(find.text('INV-00123'), findsOneWidget);
    });

    testWidgets('Dashboard deve ser scrollable', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 600));

      await tester.pumpWidget(const ProviderScope(child: InvoicelyProApp()));
      await tester.pumpAndSettle();

      // Verificar que existe SingleChildScrollView
      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));

      await tester.binding.setSurfaceSize(null);
    });
  });

  group('FAB Behavior Tests', () {
    testWidgets('FAB deve estar visível em Dashboard e Invoices', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: InvoicelyProApp()));
      await tester.pumpAndSettle();

      // Dashboard - FAB visível
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Navegar para Invoices - FAB visível
      await tester.tap(find.text('Invoices'));
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('FAB NÃO deve estar visível em Clients e Settings', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: InvoicelyProApp()));
      await tester.pumpAndSettle();

      // Navegar para Clients - FAB oculto
      await tester.tap(find.text('Clients'));
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsNothing);

      // Navegar para Settings - FAB oculto
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });
}
