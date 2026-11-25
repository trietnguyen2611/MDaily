# Graph Report - MDaily  (2026-11-26)

## Corpus Check
- Corpus is ~35,572 words - fits in a single context window. You may not need a graph.

## Summary
- 741 nodes · 1797 edges · 26 communities (24 shown, 2 thin omitted)
- Extraction: 87% EXTRACTED · 13% INFERRED · 0% AMBIGUOUS · INFERRED: 230 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Domain Models & Persistence
- Bonjour P2P Sync & Backup
- Apple Gallery Design & Glass
- Finance Store & Filtering
- Dashboard Waterfall & Cards
- Adaptive Posture & Navigation
- Theme Helpers & Currency
- Receipt Camera & Quick Capture
- Vision OCR & AI Assistant
- Add Transaction Form Flow
- App Settings & Preferences
- iPhone Duo Right Rail
- Tab Navigation & Glass Dock
- Brand Logo & App Icons
- Localized Enum Titles
- Currency Formatting & Localization
- App Entry & Documentation
- Local Reminder Notifications
- Report Chart Granularity
- Recurring Schedules & Detail
- SwiftUI Views & Charts
- Light & Dark Appearance
- Time Filter Presets
- Dashboard View Modes
- Foundation Core Imports
- Transaction Kind Filter

## God Nodes (most connected - your core abstractions)
1. `FinanceStore` - 111 edges
2. `Transaction` - 53 edges
3. `Image` - 48 edges
4. `DashboardView` - 45 edges
5. `ReportsView` - 42 edges
6. `AdaptiveRootView` - 38 edges
7. `CategoryItem` - 33 edges
8. `BonjourSyncService` - 33 edges
9. `Language` - 33 edges
10. `AdaptiveLayoutProfile` - 31 edges

## Surprising Connections (you probably didn't know these)
- `On-Device Vision OCR & Apple Foundation Models (AFM)` --conceptually_related_to--> `AFMService`  [INFERRED]
  README.md → MDaily/Services/AFMService.swift
- `Bonjour Peer-to-Peer LAN Sync (_mdaily-sync._tcp)` --conceptually_related_to--> `BonjourSyncService`  [INFERRED]
  README.md → MDaily/Services/BonjourSyncService.swift
- `Expense & Income Tracking with Receipts` --conceptually_related_to--> `FinanceStore`  [INFERRED]
  README.md → MDaily/Services/FinanceStore.swift
- `iPhone Duo Adaptive UI (Folded / Unfolded Right Rail + Inspector)` --conceptually_related_to--> `DevicePostureService`  [INFERRED]
  README.md → MDaily/Services/DevicePostureService.swift
- `iPhone Duo Adaptive UI (Folded / Unfolded Right Rail + Inspector)` --conceptually_related_to--> `AdaptiveRootView`  [INFERRED]
  README.md → MDaily/Views/Navigation/AdaptiveRootView.swift

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **iPhone Duo Adaptive Posture & Navigation System** — readme_iphone_duo_adaptive_ui, mdaily_services_devicepostureservice_devicepostureservice, mdaily_views_navigation_adaptiverootview_adaptiverootview, mdaily_views_navigation_duorightrailshell_duorightrailshell [INFERRED 0.95]
- **Apple Gallery Design System & Liquid Glass Implementation** — design_apple_design_system, mdaily_designsystem_mdailytheme_mdailycolors, mdaily_designsystem_mdailytheme_mdailytypography, mdaily_designsystem_glasssurfacemodifiers_mdailyglasssurfacemodifier [INFERRED 0.95]

## Communities (26 total, 2 thin omitted)

### Community 0 - "Domain Models & Persistence"
Cohesion: 0.05
Nodes (29): CategoryItem, .resolvedIconName, RecurringTransaction, ChatMessageSwift, SyncMergeStats, SyncPayload, Transaction, TransactionKind (+21 more)

### Community 1 - "Bonjour P2P Sync & Backup"
Cohesion: 0.05
Nodes (20): BonjourSyncError, connectionFailed, .errorDescription, invalidFrame, storeUnavailable, timeout, BonjourSyncService, .deviceDisplayName (+12 more)

### Community 2 - "Apple Gallery Design & Glass"
Cohesion: 0.05
Nodes (28): Apple Gallery Design System (DESIGN.md), Action Blue & Monochrome Surface Palette (#0066cc, #2997ff, #1d1d1f, #f5f5f7), Responsive Breakpoints & Collapsing Strategy, SF Pro Display & Text Tight Typography Scale, MDailyGlassContainer, .body, MDailyGlassSurfaceModifier, .resolvedGlass (+20 more)

### Community 3 - "Finance Store & Filtering"
Cohesion: 0.05
Nodes (33): TimeFilterMode, dateRange, preset, specificDate, specificMonth, specificYear, CustomTimeFilterSheet, .body (+25 more)

### Community 4 - "Dashboard Waterfall & Cards"
Cohesion: 0.06
Nodes (34): TransactionCompactRow, .amountColor, .body, .categoryIcon, .categoryItem, .categoryLabel, .cleanNote, .iconTint (+26 more)

### Community 5 - "Adaptive Posture & Navigation"
Cohesion: 0.06
Nodes (27): AppKit, Combine, CoreGraphics, AdaptiveLayoutProfile, .id, iPhoneDuoFolded, iPhoneDuoUnfolded, mac (+19 more)

### Community 6 - "Theme Helpers & Currency"
Cohesion: 0.09
Nodes (21): Image, .categoryFilterMenu, .emptyStateView, .expenseStatBlock, .filterAndSearchToolbar, .incomeStatBlock, .netBalanceBlock, .viewModeToggle (+13 more)

### Community 7 - "Receipt Camera & Quick Capture"
Cohesion: 0.07
Nodes (14): AVFoundation, CameraCaptureController, .isCameraHardwareAvailable, CameraPreviewUIView, .layerClass, .previewLayer, CameraPreviewView, QuickCaptureView (+6 more)

### Community 8 - "Vision OCR & AI Assistant"
Cohesion: 0.09
Nodes (15): FoundationModels, ImageIO, AFMService, AFMStatus, ExtractionCache, ExtractionResult, .category, ChatbotView (+7 more)

### Community 9 - "Add Transaction Form Flow"
Cohesion: 0.16
Nodes (9): AddTransactionView, .actionButtonsRow, .body, .filteredCategories, .headerRow, .horizontalPadding, .isEnglish, .photoSection (+1 more)

### Community 10 - "App Settings & Preferences"
Cohesion: 0.19
Nodes (8): SettingsView, .adaptiveLayoutSection, .aiSection, .appearanceLanguageCurrencySection, .bonjourSyncSection, .dataManagementSection, .hardwareBadgeText, .isEnglish

### Community 11 - "iPhone Duo Right Rail"
Cohesion: 0.24
Nodes (5): DuoRightNavigationRail, .body, DuoRightRailShell, .body, .leadingSafeMargin

### Community 12 - "Tab Navigation & Glass Dock"
Cohesion: 0.19
Nodes (9): AppTab, addTransaction, dashboard, .iconName, .id, reports, settings, PhoneBottomGlassDock (+1 more)

### Community 13 - "Brand Logo & App Icons"
Cohesion: 0.14
Nodes (14): MDaily Logo Asset (md.icon/Assets/MDaily.png), MDaily AppIcon (AppIcon-1024), MDaily AppIcon (AppIcon-128@1x), MDaily AppIcon (AppIcon-128@2x), MDaily AppIcon (AppIcon-16@1x), MDaily AppIcon (AppIcon-16@2x), MDaily AppIcon (AppIcon-256@1x), MDaily AppIcon (AppIcon-256@2x) (+6 more)

### Community 14 - "Localized Enum Titles"
Cohesion: 0.27
Nodes (6): Language, .displayName, en, .id, .title, vi

### Community 15 - "Currency Formatting & Localization"
Cohesion: 0.15
Nodes (10): Currency, .displayName, eur, gbp, .id, jpy, .symbol, .title (+2 more)

### Community 16 - "App Entry & Documentation"
Cohesion: 0.18
Nodes (7): MDailyApp, .body, Bonjour Peer-to-Peer LAN Sync (_mdaily-sync._tcp), Expense & Income Tracking with Receipts, iPhone Duo Adaptive UI (Folded / Unfolded Right Rail + Inspector), MDaily Pure Native SwiftUI Multiplatform App, On-Device Vision OCR & Apple Foundation Models (AFM)

### Community 17 - "Local Reminder Notifications"
Cohesion: 0.29
Nodes (3): NotificationService, .hasNotificationCenterBundle, UserNotifications

### Community 18 - "Report Chart Granularity"
Cohesion: 0.22
Nodes (7): ReportGranularity, day, .id, month, week, PeriodBucket, .net

### Community 19 - "Recurring Schedules & Detail"
Cohesion: 0.25
Nodes (8): RepeatInterval, daily, .id, monthly, none, weekly, yearly, .detailsFormCard

### Community 21 - "Light & Dark Appearance"
Cohesion: 0.29
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

## Knowledge Gaps
- **152 isolated node(s):** `.resolvedGlass`, `.body`, `.resolvedIconName`, `none`, `daily` (+147 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 228 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `FinanceStore` connect `Domain Models & Persistence` to `Bonjour P2P Sync & Backup`, `Apple Gallery Design & Glass`, `Finance Store & Filtering`, `Dashboard Waterfall & Cards`, `Adaptive Posture & Navigation`, `Theme Helpers & Currency`, `Receipt Camera & Quick Capture`, `Vision OCR & AI Assistant`, `Add Transaction Form Flow`, `App Settings & Preferences`, `Localized Enum Titles`, `Currency Formatting & Localization`, `App Entry & Documentation`, `Light & Dark Appearance`, `Dashboard View Modes`?**
  _High betweenness centrality (0.323) - this node is a cross-community bridge._
- **Are the 21 inferred relationships involving `FinanceStore` (e.g. with `.sendMessage()` and `.activeCategoryTitle`) actually correct?**
  _`FinanceStore` has 21 INFERRED edges - model-reasoned connections that need verification._
- **What connects `.resolvedGlass`, `.body`, `.resolvedIconName` to the rest of the system?**
  _152 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Domain Models & Persistence` be split into smaller, more focused modules?**
  _Cohesion score 0.05025773195876289 - nodes in this community are weakly interconnected._
- **Why does `AdaptiveRootView` connect `Adaptive Posture & Navigation` to `Domain Models & Persistence`, `Bonjour P2P Sync & Backup`, `Apple Gallery Design & Glass`, `Finance Store & Filtering`, `Dashboard Waterfall & Cards`, `Theme Helpers & Currency`, `Tab Navigation & Glass Dock`, `App Entry & Documentation`, `SwiftUI Views & Charts`, `Transaction Kind Filter`?**
  _High betweenness centrality (0.087) - this node is a cross-community bridge._
- **Are the 10 inferred relationships involving `Transaction` (e.g. with `.clearAllData()` and `.deleteTransaction()`) actually correct?**
  _`Transaction` has 10 INFERRED edges - model-reasoned connections that need verification._
- **Should `Bonjour P2P Sync & Backup` be split into smaller, more focused modules?**
  _Cohesion score 0.0502283105022831 - nodes in this community are weakly interconnected._