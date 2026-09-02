<script setup>
import { computed, onMounted } from 'vue';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import wootConstants from 'dashboard/constants/globals';

const props = defineProps({
  items: {
    type: Array,
    default: () => [],
  },
  activeTab: {
    type: String,
    default: wootConstants.ASSIGNEE_TYPE.ALL,
  },
});

const emit = defineEmits(['chatTabChange']);

const visibleItems = computed(() => {
  const allConversationsItem = props.items.find(
    item => item.key === wootConstants.ASSIGNEE_TYPE.ALL
  );

  if (!allConversationsItem) return [];

  return [
    {
      ...allConversationsItem,
      name: 'Todas as conversas',
    },
  ];
});

const activeTabIndex = computed(() => {
  return visibleItems.value.findIndex(item => item.key === props.activeTab);
});

const onTabChange = selectedTabIndex => {
  if (selectedTabIndex >= 0 && selectedTabIndex < visibleItems.value.length) {
    const selectedItem = visibleItems.value[selectedTabIndex];
    if (selectedItem.key !== props.activeTab) {
      emit('chatTabChange', selectedItem.key);
    }
  }
};

onMounted(() => {
  if (props.activeTab !== wootConstants.ASSIGNEE_TYPE.ALL) {
    emit('chatTabChange', wootConstants.ASSIGNEE_TYPE.ALL);
  }
});

const keyboardEvents = {
  'Alt+KeyN': {
    action: () => {
      if (props.activeTab !== wootConstants.ASSIGNEE_TYPE.ALL) {
        emit('chatTabChange', wootConstants.ASSIGNEE_TYPE.ALL);
      }
    },
  },
};

useKeyboardEvents(keyboardEvents);
</script>

<template>
  <woot-tabs
    :index="activeTabIndex"
    class="w-full px-3 -mt-1 py-0 [&_ul]:p-0 h-10"
    @change="onTabChange"
  >
    <woot-tabs-item
      v-for="(item, index) in visibleItems"
      :key="item.key"
      class="text-sm [&_a]:font-medium"
      :index="index"
      :name="item.name"
      :count="item.count"
      is-compact
    />
  </woot-tabs>
</template>
