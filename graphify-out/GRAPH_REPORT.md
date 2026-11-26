# Graph Report - MDaily  (2026-11-26)

## Corpus Check
- 33 files · ~32,701 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 6 file(s) not represented in the graph (top: (none) 2, .pbxproj 1, .xcscheme 1)

## Summary
- 727 nodes · 1709 edges · 49 communities (31 shown, 18 thin omitted)
- Extraction: 88% EXTRACTED · 12% INFERRED · 0% AMBIGUOUS · INFERRED: 206 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `642f314b`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- FinanceStore
- Bonjour P2P Sync & Backup
- Apple Gallery Design & Glass
- Finance Store & Filtering
- TransactionDetailView
- AdaptiveRootView
- Theme Helpers & Currency
- Receipt Camera & Quick Capture
- Vision OCR & AI Assistant
- Add Transaction Form Flow
- String
- AppTab
- Brand Logo & App Icons
- Localized Enum Titles
- Currency Formatting & Localization
- App Entry & Documentation
- TransactionTextCard
- Report Chart Granularity
- Recurring Schedules & Detail
- SwiftUI
- Light & Dark Appearance
- Time Filter Presets
- Dashboard View Modes
- Foundation Core Imports
- Transaction Kind Filter
- TimeFilterMode
- RecurringTransaction
- AdaptiveLayoutProfile
- CategoryItem
- DevicePostureService
- Identifiable
- Transaction
- TransactionCompactRow
- Hashable

## God Nodes (most connected - your core abstractions)
1. `FinanceStore` - 109 edges
2. `Transaction` - 54 edges
3. `DashboardView` - 43 edges
4. `Image` - 42 edges
5. `ReportsView` - 42 edges
6. `CategoryItem` - 33 edges
7. `BonjourSyncService` - 33 edges
8. `Language` - 32 edges
9. `AdaptiveRootView` - 32 edges
10. `AddTransactionView` - 31 edges

## Surprising Connections (you probably didn't know these)
- `Expense & Income Tracking with Receipts` --conceptually_related_to--> `FinanceStore`  [INFERRED]
  README.md → MDaily/Services/FinanceStore.swift
- `Bonjour Peer-to-Peer LAN Sync (_mdaily-sync._tcp)` --conceptually_related_to--> `BonjourSyncService`  [INFERRED]
  README.md → MDaily/Services/BonjourSyncService.swift
- `On-Device Vision OCR & Apple Foundation Models (AFM)` --conceptually_related_to--> `AFMService`  [INFERRED]
  README.md → MDaily/Services/AFMService.swift
- `Pill CTA Grammar, Radius Scale & Scale-0.95 Press State` --conceptually_related_to--> `MDailyPressButtonStyle`  [INFERRED]
  DESIGN.md → MDaily/DesignSystem/MDailyTheme.swift
- `iPhone Duo Adaptive UI (Folded / Unfolded Right Rail + Inspector)` --conceptually_related_to--> `DevicePostureService`  [INFERRED]
  README.md → MDaily/Services/DevicePostureService.swift

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Apple Gallery Design System & Liquid Glass Implementation** — design_apple_design_system, mdaily_designsystem_mdailytheme_mdailycolors, mdaily_designsystem_mdailytheme_mdailytypography, mdaily_designsystem_glasssurfacemodifiers_mdailyglasssurfacemodifier [INFERRED 0.95]
- **iPhone Duo Adaptive Posture & Navigation System** — readme_iphone_duo_adaptive_ui, mdaily_services_devicepostureservice_devicepostureservice, mdaily_views_navigation_adaptiverootview_adaptiverootview, mdaily_views_navigation_duorightrailshell_duorightrailshell [INFERRED 0.95]

## Communities (49 total, 18 thin omitted)

### Community 0 - "FinanceStore"
Cohesion: 0.05
Nodes (20): FinanceStore, .currencySymbol, .currentDeviceName, .dataFileURL, .storeDirectoryURL, LegacyCategoryItem, LegacyExpense, LegacyRecurringExpense (+12 more)

### Community 1 - "Bonjour P2P Sync & Backup"
Cohesion: 0.07
Nodes (13): SyncMergeStats, SyncPayload, BonjourSyncService, .deviceDisplayName, DiscoveredPeer, ReadyContinuationBox, BonjourSyncView, .body (+5 more)

### Community 2 - "Apple Gallery Design & Glass"
Cohesion: 0.05
Nodes (22): Apple Gallery Design System (DESIGN.md), Action Blue & Monochrome Surface Palette (#0066cc, #2997ff, #1d1d1f, #f5f5f7), Responsive Breakpoints & Collapsing Strategy, SF Pro Display & Text Tight Typography Scale, MDailyGlassContainer, .body, MDailyGlassSurfaceModifier, .resolvedGlass (+14 more)

### Community 3 - "Finance Store & Filtering"
Cohesion: 0.06
Nodes (35): Image, MDailyCloseButton, .body, .topHeader, CustomTimeFilterSheet, .body, .isEnglish, CustomTimeTab (+27 more)

### Community 4 - "TransactionDetailView"
Cohesion: 0.17
Nodes (9): .inspectorContent, TransactionDetailView, .amountHeaderSection, .body, .currentCategoryItem, .filteredCategories, .footerActionsSection, .isEnglish (+1 more)

### Community 5 - "AdaptiveRootView"
Cohesion: 0.16
Nodes (7): AdaptiveRootView, .body, .filteredTransactions, .inlineInspectorBinding, .resolvedColorScheme, .sidebarSelectionBinding, .standardPhoneHeader

### Community 6 - "Theme Helpers & Currency"
Cohesion: 0.14
Nodes (13): BarDatum, PeriodBucket, .net, ReportsView, .cashflowBarChartCard, .categoryBreakdownCard, .categoryManagerSection, .headerSection (+5 more)

### Community 7 - "Receipt Camera & Quick Capture"
Cohesion: 0.11
Nodes (7): CameraCaptureController, .isCameraHardwareAvailable, QuickCaptureView, .body, .flashIconName, .iOSCaptureBody, .isEnglish

### Community 8 - "Vision OCR & AI Assistant"
Cohesion: 0.09
Nodes (15): FoundationModels, ImageIO, AFMService, AFMStatus, ExtractionCache, ExtractionResult, .category, ChatbotView (+7 more)

### Community 9 - "Add Transaction Form Flow"
Cohesion: 0.12
Nodes (12): AddTransactionView, .actionButtonsRow, .body, .filteredCategories, .formCardSection, .headerRow, .horizontalPadding, .isEnglish (+4 more)

### Community 10 - "String"
Cohesion: 0.23
Nodes (6): .body, TransactionContextMenuItems, .body, TransactionFormatHelper, .body, .body

### Community 11 - "AppTab"
Cohesion: 0.11
Nodes (15): MDailyPressButtonStyle, AppTab, addTransaction, dashboard, .iconName, .id, reports, settings (+7 more)

### Community 13 - "Brand Logo & App Icons"
Cohesion: 0.14
Nodes (14): MDaily Logo Asset (md.icon/Assets/MDaily.png), MDaily AppIcon (AppIcon-1024), MDaily AppIcon (AppIcon-128@1x), MDaily AppIcon (AppIcon-128@2x), MDaily AppIcon (AppIcon-16@1x), MDaily AppIcon (AppIcon-16@2x), MDaily AppIcon (AppIcon-256@1x), MDaily AppIcon (AppIcon-256@2x) (+6 more)

### Community 14 - "Localized Enum Titles"
Cohesion: 0.30
Nodes (6): Language, .displayName, en, .id, .title, vi

### Community 15 - "Currency Formatting & Localization"
Cohesion: 0.20
Nodes (10): Currency, .displayName, eur, gbp, .id, jpy, .symbol, .title (+2 more)

### Community 16 - "App Entry & Documentation"
Cohesion: 0.18
Nodes (7): MDailyApp, .body, Bonjour Peer-to-Peer LAN Sync (_mdaily-sync._tcp), Expense & Income Tracking with Receipts, iPhone Duo Adaptive UI (Folded / Unfolded Right Rail + Inspector), MDaily Pure Native SwiftUI Multiplatform App, On-Device Vision OCR & Apple Foundation Models (AFM)

### Community 17 - "TransactionTextCard"
Cohesion: 0.19
Nodes (9): TransactionPhotoCard, .categoryIcon, .categoryItem, TransactionTextCard, .amountColor, .categoryIcon, .categoryItem, .cleanNote (+1 more)

### Community 18 - "Report Chart Granularity"
Cohesion: 0.33
Nodes (5): ReportGranularity, day, .id, month, week

### Community 19 - "Recurring Schedules & Detail"
Cohesion: 0.25
Nodes (8): RepeatInterval, daily, .id, monthly, none, weekly, yearly, .detailsFormCard

### Community 20 - "SwiftUI"
Cohesion: 0.06
Nodes (20): AppKit, AVFoundation, Charts, Combine, CoreGraphics, BonjourSyncError, connectionFailed, .errorDescription (+12 more)

### Community 21 - "Light & Dark Appearance"
Cohesion: 0.33
Nodes (5): AppearanceMode, dark, .id, light, system

### Community 22 - "Time Filter Presets"
Cohesion: 0.29
Nodes (7): TimePreset, all, .id, thisMonth, thisWeek, thisYear, today

### Community 23 - "Dashboard View Modes"
Cohesion: 0.33
Nodes (5): DashboardViewMode, .iconName, .id, list, waterfall

### Community 25 - "Transaction Kind Filter"
Cohesion: 0.33
Nodes (5): TransactionKindFilter, all, expense, .id, income

### Community 26 - "TimeFilterMode"
Cohesion: 0.15
Nodes (6): TimeFilterMode, dateRange, preset, specificDate, specificMonth, specificYear

### Community 27 - "RecurringTransaction"
Cohesion: 0.22
Nodes (7): RecurringTransaction, TransactionKind, expense, .id, income, .signPrefix, PersistedStoreData

### Community 28 - "AdaptiveLayoutProfile"
Cohesion: 0.21
Nodes (9): AdaptiveLayoutProfile, .id, iPhoneDuoFolded, iPhoneDuoUnfolded, mac, pad, standardPhone, .supportsInlineInspector (+1 more)

### Community 29 - "CategoryItem"
Cohesion: 0.27
Nodes (6): CategoryItem, .resolvedIconName, .categoryLabel, .categoryLabel, .categoryLabel, .currentCategoryLabel

### Community 31 - "Identifiable"
Cohesion: 0.33
Nodes (4): ChatMessageSwift, .groupedByDay, DayGroup, .id

### Community 33 - "TransactionCompactRow"
Cohesion: 0.33
Nodes (6): TransactionCompactRow, .amountColor, .categoryIcon, .categoryItem, .cleanNote, .iconTint

### Community 34 - "Hashable"
Cohesion: 0.40
Nodes (4): FormField, amount, newCategory, note

## Knowledge Gaps
- **148 isolated node(s):** `.resolvedGlass`, `.body`, `iPhoneDuoFolded`, `iPhoneDuoUnfolded`, `standardPhone` (+143 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 234 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **18 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `FinanceStore` connect `FinanceStore` to `Bonjour P2P Sync & Backup`, `Finance Store & Filtering`, `TransactionDetailView`, `AdaptiveRootView`, `Theme Helpers & Currency`, `Receipt Camera & Quick Capture`, `Vision OCR & AI Assistant`, `Add Transaction Form Flow`, `Localized Enum Titles`, `Currency Formatting & Localization`, `App Entry & Documentation`, `TransactionTextCard`, `SwiftUI`, `Light & Dark Appearance`, `Dashboard View Modes`, `TimeFilterMode`, `RecurringTransaction`, `CategoryItem`, `DevicePostureService`, `Identifiable`, `Transaction`, `TransactionCompactRow`?**
  _High betweenness centrality (0.314) - this node is a cross-community bridge._
- **Are the 21 inferred relationships involving `FinanceStore` (e.g. with `.sendMessage()` and `.activeCategoryTitle`) actually correct?**
  _`FinanceStore` has 21 INFERRED edges - model-reasoned connections that need verification._
- **What connects `.resolvedGlass`, `.body`, `iPhoneDuoFolded` to the rest of the system?**
  _148 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `FinanceStore` be split into smaller, more focused modules?**
  _Cohesion score 0.05092592592592592 - nodes in this community are weakly interconnected._
- **Why does `ReportsView` connect `Theme Helpers & Currency` to `Transaction`, `FinanceStore`, `Apple Gallery Design & Glass`, `Finance Store & Filtering`, `Report Chart Granularity`, `SwiftUI`, `TimeFilterMode`, `RecurringTransaction`, `AdaptiveLayoutProfile`, `CategoryItem`?**
  _High betweenness centrality (0.087) - this node is a cross-community bridge._
- **Are the 11 inferred relationships involving `Transaction` (e.g. with `.clearAllData()` and `.deleteTransaction()`) actually correct?**
  _`Transaction` has 11 INFERRED edges - model-reasoned connections that need verification._
- **Should `Bonjour P2P Sync & Backup` be split into smaller, more focused modules?**
  _Cohesion score 0.07017543859649122 - nodes in this community are weakly interconnected._