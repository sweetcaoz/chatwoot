# Modern Kanban Board Frontend Architecture & Design Proposal

## Executive Summary

This document outlines a comprehensive proposal for redesigning Chatwoot's Kanban board to follow modern design patterns, align with Chatwoot's established design language, and provide a superior user experience. The current implementation shows significant deviations from the platform's design standards and lacks the polished aesthetic expected from a modern productivity tool.

## Current State Analysis

### Design Inconsistencies Identified

#### ❌ Current Issues
1. **Deprecated Components**: Uses deprecated `WootInput` components (generates console warnings)
2. **CSS Variables**: Relies on legacy `--var` syntax instead of Chatwoot's modern `text-n-slate-*` classes
3. **Layout Patterns**: Custom classes (`kanban-*`) instead of established utility patterns
4. **Filter Design**: Outdated form styling that doesn't match the conversation page
5. **Visual Hierarchy**: Poor spacing and typography inconsistent with the platform
6. **Drag & Drop UX**: Basic implementation lacking modern visual feedback

#### ✅ Current Strengths
1. **Vue 3 Composition API**: Modern reactive architecture with `<script setup>`
2. **Drag & Drop Functionality**: Working native HTML5 drag and drop
3. **Real-time Updates**: ActionCable integration for live synchronization
4. **Component Structure**: Well-organized component hierarchy

## Design System Alignment

### Target Design Language

Based on Chatwoot's established patterns from `clause_style.md`, the new Kanban board should follow:

#### Color System
```css
/* Primary Text */
.text-n-slate-12  /* High contrast for titles */
.text-n-slate-11  /* Secondary text */
.text-n-slate-10  /* Tertiary text */

/* Backgrounds */
.bg-n-solid-2     /* Main background surfaces */
.bg-n-solid-3     /* Card and button backgrounds */
.bg-n-alpha-1     /* Subtle hover states */
.bg-n-alpha-2     /* Interactive backgrounds */

/* Borders */
.border-n-weak    /* Subtle borders */
.border-n-container /* Container outlines */
```

#### Typography
- **Font**: Inter system stack (already established)
- **Sizes**: `text-sm` (14px), `text-base` (16px), `text-lg` (18px)
- **Weights**: `font-medium` (500), `font-semibold` (600)
- **Line Heights**: `leading-5` (20px), `leading-6` (24px)

#### Spacing & Layout
- **Flexbox**: `flex items-center gap-2` patterns
- **Padding**: `px-2` (8px), `py-1` (4px), `p-3` (12px)
- **Margins**: `mb-2` (8px), `mt-4` (16px)
- **Border Radius**: `rounded-lg` (8px), `rounded-xl` (12px)

#### Icons
- **System**: Lucide icons with `i-lucide-*` classes
- **Sizes**: `size-4` (16px), `size-5` (20px), `size-6` (24px)

## Dynamic Column Layout System

### Responsive Column Sizing Strategy

The Kanban board must dynamically adjust column widths based on:
1. **Viewport width**: Available horizontal space
2. **Number of stages**: Total columns to display
3. **Content density**: Minimum usable column width
4. **Scroll behavior**: When columns exceed viewport

#### Column Width Calculation Logic
```typescript
// composables/useKanbanLayout.ts
export function useKanbanLayout() {
  const containerRef = ref<HTMLElement>()
  const stageCount = ref(0)
  
  const columnDimensions = computed(() => {
    if (!containerRef.value) return { width: 320, minWidth: 280, maxWidth: 400 }
    
    const containerWidth = containerRef.value.offsetWidth
    const padding = 16 // Container padding
    const gap = 16 // Gap between columns
    const availableWidth = containerWidth - (padding * 2) - (gap * Math.max(0, stageCount.value - 1))
    
    // Calculate optimal column width
    const idealWidth = 320 // Ideal column width in pixels
    const minWidth = 280   // Minimum usable width
    const maxWidth = 400   // Maximum width to prevent overly wide columns
    
    // Determine if all columns fit in viewport
    const totalIdealWidth = (idealWidth * stageCount.value) + (gap * (stageCount.value - 1))
    
    if (totalIdealWidth <= availableWidth) {
      // All columns fit - distribute extra space or use ideal width
      const calculatedWidth = Math.min(
        maxWidth,
        Math.max(idealWidth, availableWidth / stageCount.value)
      )
      
      return {
        width: calculatedWidth,
        minWidth,
        maxWidth,
        strategy: 'fit-all'
      }
    } else {
      // Columns exceed viewport - use scroll with minimum width
      return {
        width: Math.max(minWidth, idealWidth),
        minWidth,
        maxWidth,
        strategy: 'scroll'
      }
    }
  })
  
  return {
    containerRef,
    stageCount,
    columnDimensions
  }
}
```

### Responsive Breakpoint Strategy

```typescript
// Column width behavior across device sizes
const responsiveConfig = {
  // Mobile Portrait: Stack vertically or use tabs
  mobile: {
    maxWidth: 640,
    behavior: 'tabs', // Switch to tab-based navigation
    columnWidth: '100%'
  },
  
  // Mobile Landscape: 1-2 columns with scroll
  mobileLandscape: {
    maxWidth: 896, 
    minColumns: 1,
    maxColumns: 2,
    columnWidth: 'calc(50% - 8px)', // 2 columns with gap
    behavior: 'scroll'
  },
  
  // Tablet: 2-3 columns, adaptive width
  tablet: {
    maxWidth: 1024,
    minColumns: 2,
    maxColumns: 3,
    minColumnWidth: 280,
    idealColumnWidth: 320,
    behavior: 'adaptive'
  },
  
  // Desktop: 3-5 columns, optimal experience
  desktop: {
    maxWidth: 1440,
    minColumns: 3,
    maxColumns: 5,
    minColumnWidth: 280,
    idealColumnWidth: 320,
    maxColumnWidth: 400,
    behavior: 'fit-or-scroll'
  },
  
  // Large Desktop: 4+ columns, maximum usability
  largeDesktop: {
    minWidth: 1441,
    minColumns: 4,
    maxColumns: 8,
    minColumnWidth: 300,
    idealColumnWidth: 340,
    maxColumnWidth: 420,
    behavior: 'fit-or-scroll'
  }
}
```

## Modern Kanban Board Architecture

### Layout Structure

```
┌─────────────────────────────────────────────────────────────────┐
│ Header: Title + Actions (Settings, Filters, Search)            │
├─────────────────────────────────────────────────────────────────┤
│ Filters Bar: Quick filters with clear/apply actions            │
├─────────────────────────────────────────────────────────────────┤
│ Board Container: Dynamic width columns with smart scrolling    │
│ ┌─────────┬─────────┬─────────┬─────────┬─────────┐             │
│ │Stage 1  │Stage 2  │Stage 3  │Stage 4  │Stage 5  │             │
│ │ (n)     │ (n)     │ (n)     │ (n)     │ (n)     │             │
│ │[Card]   │[Card]   │[Card]   │[Card]   │[Card]   │             │
│ │[Card]   │[Card]   │[Card]   │         │[Card]   │             │
│ │[Card]   │         │         │         │         │             │
│ └─────────┴─────────┴─────────┴─────────┴─────────┘             │
│ ← Dynamic width based on viewport and stage count →             │
└─────────────────────────────────────────────────────────────────┘
```

### Component Architecture

#### 1. KanbanBoard.vue (Main Container)
```vue
<template>
  <div class="flex flex-col h-full bg-n-solid-2">
    <!-- Header -->
    <KanbanHeader 
      :total-conversations="totalConversations"
      @settings="openSettings"
      @refresh="refreshBoard"
    />
    
    <!-- Filters -->
    <KanbanFilters 
      v-model:filters="activeFilters"
      :is-loading="isLoading"
      @clear="clearFilters"
    />
    
    <!-- Board -->
    <div class="flex-1 overflow-hidden">
      <KanbanBoardContainer
        :stages="stages"
        :conversations="filteredConversations"
        :filters="activeFilters"
        @move="moveConversation"
        @quick-reply="handleQuickReply"
        @assign="handleAssign"
      />
    </div>
  </div>
</template>
```

#### 2. KanbanBoardContainer.vue (Dynamic Layout Container)
```vue
<template>
  <div 
    ref="containerRef"
    class="kanban-board-container h-full"
    :class="layoutClasses"
  >
    <!-- Desktop/Tablet: Dynamic column layout -->
    <div 
      v-if="!isMobile"
      class="flex gap-4 p-4 h-full"
      :class="scrollStrategy === 'scroll' ? 'overflow-x-auto' : 'overflow-x-hidden'"
      :style="containerStyles"
    >
      <KanbanColumn
        v-for="stage in stages"
        :key="stage.id"
        :stage="stage"
        :conversations="getConversationsForStage(stage.id)"
        :is-loading="isLoading"
        :style="columnStyles"
        class="flex-shrink-0"
        @drop="handleDrop"
        @load-more="loadMoreConversations"
      />
    </div>
    
    <!-- Mobile: Tab-based navigation -->
    <div v-else class="h-full flex flex-col">
      <!-- Stage Tabs -->
      <div class="flex overflow-x-auto bg-white border-b border-n-weak">
        <button
          v-for="(stage, index) in stages"
          :key="stage.id"
          @click="activeStageIndex = index"
          class="flex-shrink-0 px-4 py-3 text-sm font-medium transition-colors"
          :class="[
            activeStageIndex === index 
              ? 'text-blue-600 border-b-2 border-blue-600 bg-blue-50' 
              : 'text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-1'
          ]"
        >
          <i 
            v-if="stage.icon"
            :class="`i-lucide-${stage.icon} size-4 mr-2`"
            :style="{ color: stage.color }"
          />
          {{ stage.name }}
          <span class="ml-2 px-2 py-0.5 text-xs bg-n-alpha-1 rounded-full">
            {{ getConversationsForStage(stage.id).length }}
          </span>
        </button>
      </div>
      
      <!-- Active Stage Content -->
      <div class="flex-1 overflow-hidden">
        <KanbanColumn
          :stage="stages[activeStageIndex]"
          :conversations="getConversationsForStage(stages[activeStageIndex]?.id)"
          :is-loading="isLoading"
          class="h-full w-full"
          mobile-mode
          @drop="handleDrop"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useKanbanLayout } from '@/composables/useKanbanLayout'
import { useBreakpoints } from '@vueuse/core'

const { containerRef, stageCount, columnDimensions } = useKanbanLayout()
const breakpoints = useBreakpoints({
  mobile: 640,
  tablet: 1024,
  desktop: 1440
})

const stages = ref([])
const activeStageIndex = ref(0)

const isMobile = computed(() => !breakpoints.greater('mobile').value)
const isTablet = computed(() => breakpoints.between('mobile', 'desktop').value)
const isDesktop = computed(() => breakpoints.greater('desktop').value)

// Update stage count when stages change
watchEffect(() => {
  stageCount.value = stages.value.length
})

const scrollStrategy = computed(() => columnDimensions.value.strategy)

const layoutClasses = computed(() => ({
  'kanban-board--mobile': isMobile.value,
  'kanban-board--tablet': isTablet.value,
  'kanban-board--desktop': isDesktop.value,
  'kanban-board--scrollable': scrollStrategy.value === 'scroll'
}))

const containerStyles = computed(() => {
  if (isMobile.value) return {}
  
  return {
    '--kanban-column-width': `${columnDimensions.value.width}px`,
    '--kanban-column-min-width': `${columnDimensions.value.minWidth}px`,
    '--kanban-column-max-width': `${columnDimensions.value.maxWidth}px`
  }
})

const columnStyles = computed(() => {
  if (isMobile.value) return { width: '100%' }
  
  const { width, strategy } = columnDimensions.value
  
  if (strategy === 'fit-all') {
    // Columns fit in viewport - use calculated width
    return {
      width: `${width}px`,
      minWidth: `${width}px`,
      maxWidth: `${width}px`
    }
  } else {
    // Columns need scrolling - use fixed optimal width
    return {
      width: `${width}px`,
      minWidth: `${width}px`,
      flexShrink: 0
    }
  }
})

// Handle window resize
const handleResize = () => {
  // Trigger recalculation
  containerRef.value?.dispatchEvent(new Event('resize'))
}

onMounted(() => {
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
})
</script>

<style scoped>
.kanban-board-container {
  --scroll-behavior: smooth;
}

.kanban-board--scrollable {
  scroll-snap-type: x mandatory;
}

.kanban-board--scrollable .kanban-column {
  scroll-snap-align: start;
}

/* Custom scrollbar for horizontal scroll */
.kanban-board--scrollable::-webkit-scrollbar {
  height: 8px;
}

.kanban-board--scrollable::-webkit-scrollbar-track {
  background: theme('colors.slate.100');
  border-radius: 4px;
}

.kanban-board--scrollable::-webkit-scrollbar-thumb {
  background: theme('colors.slate.300');
  border-radius: 4px;
}

.kanban-board--scrollable::-webkit-scrollbar-thumb:hover {
  background: theme('colors.slate.400');
}
</style>
```

#### 3. KanbanColumn.vue (Responsive Column Component)
```vue
<template>
  <div 
    class="kanban-column flex flex-col h-full bg-white rounded-xl border border-n-weak"
    :class="columnClasses"
  >
    <!-- Column Header -->
    <div class="flex items-center justify-between p-4 border-b border-n-weak flex-shrink-0">
      <div class="flex items-center gap-2 min-w-0 flex-1">
        <div 
          class="flex items-center justify-center size-6 rounded-md flex-shrink-0"
          :style="{ backgroundColor: stage.color + '20' }"
        >
          <i 
            :class="`i-lucide-${stage.icon} size-4`"
            :style="{ color: stage.color }"
          />
        </div>
        <h3 class="text-sm font-semibold text-n-slate-12 truncate">
          {{ stage.name }}
        </h3>
        <span class="px-2 py-0.5 text-xs font-medium bg-n-alpha-1 text-n-slate-11 rounded-full flex-shrink-0">
          {{ conversations.length }}
        </span>
      </div>
      
      <button 
        v-if="!mobileMode"
        class="p-1 hover:bg-n-alpha-1 rounded-md transition-colors flex-shrink-0"
      >
        <i class="i-lucide-more-horizontal size-4 text-n-slate-10" />
      </button>
    </div>
    
    <!-- Column Body -->
    <div 
      class="flex-1 p-3 overflow-y-auto"
      :class="{ 'p-4': mobileMode }"
      @dragover.prevent
      @drop="handleDrop"
    >
      <!-- Loading State -->
      <div v-if="isLoading && !conversations.length" class="space-y-3">
        <div 
          v-for="i in 3" 
          :key="i"
          class="animate-pulse bg-n-alpha-1 rounded-lg h-24"
        />
      </div>
      
      <!-- Conversations -->
      <div v-else-if="conversations.length" class="space-y-3">
        <KanbanCard
          v-for="conversation in conversations"
          :key="conversation.id"
          :conversation="conversation"
          :mobile-mode="mobileMode"
          @click="openConversation"
          @quick-reply="$emit('quick-reply', conversation)"
          @assign="$emit('assign', conversation)"
        />
        
        <!-- Load More Button -->
        <button
          v-if="hasMore && !isLoading"
          @click="$emit('load-more')"
          class="w-full py-3 text-sm text-n-slate-11 hover:text-n-slate-12 
                 hover:bg-n-alpha-1 rounded-lg transition-colors border-2 border-dashed border-n-weak"
        >
          Load more conversations
        </button>
        
        <!-- Loading More -->
        <div 
          v-if="isLoading && conversations.length"
          class="animate-pulse bg-n-alpha-1 rounded-lg h-20"
        />
      </div>
      
      <!-- Empty State -->
      <div 
        v-else
        class="flex flex-col items-center justify-center py-12 text-center"
        :class="{ 'py-16': mobileMode }"
      >
        <div 
          class="flex items-center justify-center size-12 rounded-xl mb-3"
          :style="{ backgroundColor: stage.color + '10' }"
        >
          <i 
            :class="`i-lucide-${stage.icon || 'inbox'} size-6`"
            :style="{ color: stage.color || 'rgb(148, 163, 184)' }"
          />
        </div>
        <p class="text-sm font-medium text-n-slate-11 mb-1">No conversations</p>
        <p class="text-xs text-n-slate-10">
          {{ mobileMode ? 'No conversations in this stage yet' : 'Drag cards here to get started' }}
        </p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import KanbanCard from './KanbanCard.vue'

const props = defineProps({
  stage: {
    type: Object,
    required: true,
  },
  conversations: {
    type: Array,
    default: () => [],
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
  mobileMode: {
    type: Boolean,
    default: false,
  },
  hasMore: {
    type: Boolean,
    default: false,
  }
})

const emit = defineEmits(['drop', 'quick-reply', 'assign', 'load-more'])

const columnClasses = computed(() => ({
  'kanban-column--mobile': props.mobileMode,
  'kanban-column--empty': !props.conversations.length,
  'kanban-column--loading': props.isLoading
}))
</script>

<style scoped>
.kanban-column {
  transition: all 0.2s ease;
}

.kanban-column--mobile {
  border-radius: 0;
  border-left: 0;
  border-right: 0;
  border-bottom: 0;
}

/* Optimized scrollbar for column content */
.kanban-column ::-webkit-scrollbar {
  width: 6px;
}

.kanban-column ::-webkit-scrollbar-track {
  background: transparent;
}

.kanban-column ::-webkit-scrollbar-thumb {
  background: theme('colors.slate.200');
  border-radius: 3px;
}

.kanban-column ::-webkit-scrollbar-thumb:hover {
  background: theme('colors.slate.300');
}
</style>
```

### Advanced Layout Features

#### Intelligent Column Management
```typescript
// composables/useIntelligentLayout.ts
export function useIntelligentLayout(stages: Ref<Stage[]>) {
  const containerWidth = ref(0)
  const preferredColumnWidth = ref(320)
  
  // Calculate optimal layout based on content and viewport
  const layoutConfiguration = computed(() => {
    const stageCount = stages.value.length
    const minColumnWidth = 280
    const maxColumnWidth = 420
    const gap = 16
    const padding = 32
    
    // Available space calculation
    const availableWidth = containerWidth.value - padding
    const totalGapWidth = gap * Math.max(0, stageCount - 1)
    const availableContentWidth = availableWidth - totalGapWidth
    
    // Determine optimal strategy
    if (stageCount === 0) {
      return { strategy: 'empty' }
    }
    
    if (stageCount === 1) {
      return {
        strategy: 'single',
        columnWidth: Math.min(maxColumnWidth, Math.max(minColumnWidth, availableContentWidth))
      }
    }
    
    if (stageCount <= 2) {
      const columnWidth = Math.min(maxColumnWidth, availableContentWidth / stageCount)
      return {
        strategy: columnWidth >= minColumnWidth ? 'fit-two' : 'scroll',
        columnWidth: Math.max(minColumnWidth, columnWidth)
      }
    }
    
    // Three or more columns
    const idealTotalWidth = preferredColumnWidth.value * stageCount + totalGapWidth
    
    if (idealTotalWidth <= availableWidth) {
      // All columns fit comfortably
      const distributedWidth = Math.min(maxColumnWidth, availableContentWidth / stageCount)
      return {
        strategy: 'fit-all',
        columnWidth: Math.max(minColumnWidth, distributedWidth)
      }
    } else {
      // Need horizontal scroll
      const maxFitColumns = Math.floor((availableContentWidth + gap) / (minColumnWidth + gap))
      return {
        strategy: 'scroll',
        columnWidth: preferredColumnWidth.value,
        visibleColumns: Math.max(1, maxFitColumns),
        scrollRequired: true
      }
    }
  })
  
  // Responsive breakpoint handling
  const responsiveAdjustments = computed(() => {
    const config = layoutConfiguration.value
    
    if (containerWidth.value < 640) {
      // Mobile - force tab mode
      return { ...config, strategy: 'tabs', forceTabMode: true }
    }
    
    if (containerWidth.value < 1024) {
      // Tablet - limit max columns
      return { 
        ...config, 
        maxVisibleColumns: 3,
        columnWidth: Math.max(300, config.columnWidth)
      }
    }
    
    return config
  })
  
  return {
    containerWidth,
    preferredColumnWidth,
    layoutConfiguration: responsiveAdjustments
  }
}
```

#### Smooth Column Transitions
```vue
<!-- Transition animations for dynamic layouts -->
<template>
  <TransitionGroup
    name="kanban-column"
    tag="div"
    class="flex gap-4 p-4 h-full transition-all duration-300 ease-out"
  >
    <KanbanColumn
      v-for="stage in stages"
      :key="stage.id"
      :stage="stage"
      :style="getColumnStyles(stage.id)"
      class="kanban-column-item"
    />
  </TransitionGroup>
</template>

<style scoped>
.kanban-column-enter-active,
.kanban-column-leave-active {
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.kanban-column-enter-from {
  opacity: 0;
  transform: scale(0.95) translateY(10px);
}

.kanban-column-leave-to {
  opacity: 0;
  transform: scale(0.95) translateY(-10px);
}

.kanban-column-move {
  transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}
</style>
```

## Enhanced Mobile Experience

### Progressive Web App Features
```vue
<!-- Mobile-optimized navigation -->
<template>
  <div class="mobile-kanban h-full flex flex-col">
    <!-- Sticky Header -->
    <div class="bg-white border-b border-n-weak sticky top-0 z-10">
      <div class="p-4">
        <h1 class="text-lg font-semibold text-n-slate-12">Kanban Board</h1>
      </div>
      
      <!-- Stage Tabs with scroll indicators -->
      <div class="relative">
        <div 
          ref="tabsContainer"
          class="flex overflow-x-auto scrollbar-hide"
          @scroll="updateScrollIndicators"
        >
          <button
            v-for="(stage, index) in stages"
            :key="stage.id"
            @click="setActiveStage(index)"
            class="flex-shrink-0 px-4 py-3 text-sm font-medium whitespace-nowrap transition-all"
            :class="getTabClasses(index)"
          >
            <i 
              v-if="stage.icon"
              :class="`i-lucide-${stage.icon} size-4 mr-2`"
              :style="{ color: isActiveStage(index) ? stage.color : '' }"
            />
            {{ stage.name }}
            <span 
              class="ml-2 px-1.5 py-0.5 text-xs rounded-full"
              :class="getCountBadgeClasses(index)"
            >
              {{ getStageConversationCount(stage.id) }}
            </span>
          </button>
        </div>
        
        <!-- Scroll indicators -->
        <div 
          v-if="showLeftIndicator"
          class="absolute left-0 top-0 bottom-0 w-8 bg-gradient-to-r from-white to-transparent pointer-events-none"
        />
        <div 
          v-if="showRightIndicator"
          class="absolute right-0 top-0 bottom-0 w-8 bg-gradient-to-l from-white to-transparent pointer-events-none"
        />
      </div>
    </div>
    
    <!-- Stage Content with swipe gestures -->
    <div class="flex-1 relative overflow-hidden">
      <div 
        class="flex h-full transition-transform duration-300 ease-out"
        :style="{ transform: `translateX(-${activeStageIndex * 100}%)` }"
      >
        <div
          v-for="(stage, index) in stages"
          :key="stage.id"
          class="w-full flex-shrink-0 h-full"
        >
          <KanbanColumn
            :stage="stage"
            :conversations="getConversationsForStage(stage.id)"
            :mobile-mode="true"
            class="h-full"
          />
        </div>
      </div>
      
      <!-- Swipe indicators -->
      <div class="absolute bottom-4 left-1/2 transform -translate-x-1/2 flex gap-2">
        <div
          v-for="(stage, index) in stages"
          :key="stage.id"
          class="w-2 h-2 rounded-full transition-all"
          :class="index === activeStageIndex ? 'bg-blue-500' : 'bg-n-alpha-2'"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useSwipe, useEventListener } from '@vueuse/core'

const activeStageIndex = ref(0)
const tabsContainer = ref()
const showLeftIndicator = ref(false)
const showRightIndicator = ref(false)

// Swipe gesture support
const { isSwiping, direction } = useSwipe(document.body, {
  threshold: 50,
  onSwipeEnd(e, direction) {
    if (direction === 'left' && activeStageIndex.value < stages.value.length - 1) {
      activeStageIndex.value++
    } else if (direction === 'right' && activeStageIndex.value > 0) {
      activeStageIndex.value--
    }
  }
})

const updateScrollIndicators = () => {
  if (!tabsContainer.value) return
  
  const { scrollLeft, scrollWidth, clientWidth } = tabsContainer.value
  showLeftIndicator.value = scrollLeft > 0
  showRightIndicator.value = scrollLeft < scrollWidth - clientWidth - 1
}

const setActiveStage = (index) => {
  activeStageIndex.value = index
  
  // Scroll active tab into view
  const tabElement = tabsContainer.value?.children[index]
  if (tabElement) {
    tabElement.scrollIntoView({ 
      behavior: 'smooth', 
      block: 'nearest',
      inline: 'center'
    })
  }
}
</script>
```

## Performance Optimizations for Dynamic Layouts

### Virtualized Scrolling with Dynamic Heights
```vue
<!-- KanbanColumn.vue with virtual scrolling -->
<template>
  <div class="kanban-column">
    <!-- Column Header -->
    <div class="column-header">
      <!-- Header content -->
    </div>
    
    <!-- Virtualized Content -->
    <RecycleScroller
      ref="scroller"
      class="flex-1"
      :items="conversations"
      :item-size="estimatedCardHeight"
      :min-item-size="120"
      key-field="id"
      v-slot="{ item, index }"
      @resize="handleItemResize"
    >
      <KanbanCard
        :conversation="item"
        :data-index="index"
        @click="openConversation(item)"
        @resize="updateItemHeight"
      />
    </RecycleScroller>
  </div>
</template>

<script setup>
import { RecycleScroller } from 'vue-virtual-scroller'

const estimatedCardHeight = ref(140)
const itemHeights = new Map()

const updateItemHeight = (conversationId, height) => {
  itemHeights.set(conversationId, height)
  
  // Update estimated height based on actual measurements
  const heights = Array.from(itemHeights.values())
  estimatedCardHeight.value = Math.round(
    heights.reduce((sum, h) => sum + h, 0) / heights.length
  )
}
</script>
```

### Efficient Re-rendering Strategy
```typescript
// composables/useKanbanPerformance.ts
export function useKanbanPerformance() {
  const renderQueue = ref([])
  const isRendering = ref(false)
  
  // Batch DOM updates for better performance
  const batchUpdate = (updateFn: () => void) => {
    renderQueue.value.push(updateFn)
    
    if (!isRendering.value) {
      isRendering.value = true
      nextTick(() => {
        requestAnimationFrame(() => {
          renderQueue.value.forEach(fn => fn())
          renderQueue.value = []
          isRendering.value = false
        })
      })
    }
  }
  
  // Debounced layout recalculation
  const recalculateLayout = useDebounceFn(() => {
    batchUpdate(() => {
      // Recalculate column dimensions
      // Update responsive breakpoints
      // Adjust scroll positions
    })
  }, 150)
  
  return {
    batchUpdate,
    recalculateLayout
  }
}
```

## Implementation Roadmap

### Phase 1: Foundation (Week 1-2)
- [ ] Set up dynamic layout system with responsive calculations
- [ ] Implement responsive column width calculations
- [ ] Basic mobile tab navigation
- [ ] Design system alignment

### Phase 2: Enhanced UX (Week 3-4)
- [ ] Advanced drag and drop with smooth animations
- [ ] Mobile swipe gestures and touch optimization
- [ ] Intelligent layout transitions
- [ ] Performance optimizations for large datasets

### Phase 3: Advanced Features (Week 5)
- [ ] Virtual scrolling for performance
- [ ] Progressive loading and lazy rendering
- [ ] Advanced mobile PWA features
- [ ] Accessibility enhancements

### Phase 4: Polish & Testing (Week 6)
- [ ] Cross-device testing and optimization
- [ ] Performance benchmarking
- [ ] Edge case handling (1 column, 10+ columns)
- [ ] Comprehensive documentation

## Conclusion

This enhanced proposal specifically addresses the dynamic nature of Kanban stages by:

1. **Intelligent Layout System**: Automatically calculates optimal column widths based on viewport and stage count
2. **Responsive Breakpoints**: Adapts from 1 to 8+ columns across all device sizes
3. **Mobile-First Design**: Seamless transition to tab-based navigation on mobile
4. **Performance-Conscious**: Virtual scrolling and optimized rendering for any number of stages
5. **Smooth Transitions**: Animated layout changes when stages are added/removed
6. **Accessibility**: Full support for keyboard navigation across dynamic layouts

The result is a truly adaptive Kanban board that provides an optimal experience regardless of how many stages administrators configure, ensuring usability from a simple 3-stage workflow to complex 10+ stage processes.

---

*This proposal ensures the Kanban board gracefully handles any number of dynamic stages while maintaining Chatwoot's design consistency and modern UX standards.*