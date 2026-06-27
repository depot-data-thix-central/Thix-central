# THIX CHAT Module - Complete Implementation Guide

## Overview

THIX CHAT is a comprehensive messaging system built with Flutter, Supabase, and Riverpod. It provides real-time messaging, group chats, collaborative features, and advanced security options.

## Architecture

### Technology Stack
- **Frontend**: Flutter with Riverpod for state management
- **Backend**: Supabase (PostgreSQL, Realtime, Storage)
- **Real-time**: Supabase Realtime subscriptions
- **Database**: 21 normalized tables with RLS policies
- **Authentication**: Supabase Auth

### Project Structure

```
lib/pages/messages/
├── models/
│   └── chat_models.dart                 # All data models (Message, Conversation, Poll, Task, etc.)
├── services/
│   ├── chat_service.dart               # Core messaging operations
│   ├── poll_service.dart               # Poll creation and voting
│   ├── task_service.dart               # Collaborative task management
│   ├── advanced_services.dart          # Scheduled messages, ephemeral, confidential, etc.
│   └── settings_service.dart           # User and conversation settings
├── providers/
│   └── chat_providers.dart             # Riverpod providers and state management
├── widgets/
│   └── message_widgets.dart            # Reusable UI components
├── pages/
│   ├── enhanced_messages_page.dart     # Main chat list
│   ├── conversation_detail_page.dart   # Single conversation view
│   └── group_settings_page.dart        # Group management and tabs
└── messages_page.dart                  # Entry point (original)
```

## Database Schema

### Core Tables

#### 1. **conversations**
- `id` (uuid): Primary key
- `name` (text): Group name or null for 1-to-1
- `is_group` (boolean): Group vs. direct message
- `description` (text): Group description
- `avatar_url` (text): Profile image
- `created_by` (uuid): Creator user ID
- `created_at`, `updated_at` (timestamptz): Timestamps

#### 2. **messages**
- `id` (uuid): Primary key
- `conversation_id` (uuid): Foreign key to conversations
- `sender_id` (uuid): Sender user ID
- `content` (text): Message text
- `message_type` (text): 'text', 'voice', 'video', 'image', 'document', 'contact'
- `file_url`, `file_name`, `file_size`: Media attachment info
- `reply_to_id` (uuid): For threaded replies
- `is_edited` (boolean): Message edit flag
- `deleted_at` (timestamptz): Soft delete timestamp

#### 3. **read_receipts**
- Tracks message delivery status: sent → delivered → read
- Stores read/delivered timestamps per user

#### 4. **message_reactions**
- Emoji reactions (👍, ❤️, 😂, etc.)
- User + message + emoji combination

#### 5. **ephemeral_messages**
- Auto-delete after configurable duration (5s, 10s, 30s, 60s, custom)
- `expires_at` triggers background cleanup

#### 6. **confidential_messages**
- PIN or biometric lock protection
- Tracks who has accessed the message

#### 7. **scheduled_messages**
- Schedule messages for future delivery
- Supports recurrence (daily, weekly, monthly)

#### 8. **polls**
- Question with options
- Anonymous or public voting
- Single or multi-select

#### 9. **collaborative_tasks**
- Title, description, assignee, priority, due date
- Status tracking: pending, in_progress, completed

#### 10. **conversation_participants**
- Roles: admin, moderator, member
- Mute duration for Do Not Disturb
- Custom display name in conversation

#### 11. **typing_indicators**
- Real-time "X is typing..." functionality

#### 12. **user_presence**
- Online/offline status
- Last seen timestamp

#### 13. **blocked_users**
- User blocklist management

#### 14. **reported_content**
- Moderation queue for flagged messages/users

#### 15. **message_drafts**
- Auto-saved message drafts per conversation

#### 16. **pinned_messages**
- Admin-pinned messages in groups

#### 17. **chat_settings**
- User-level preferences (theme, notifications, data saver, translation)

#### 18. **conversation_settings**
- Conversation-level customization (wallpaper, bubble style, encryption)

#### 19. **call_history**
- Audio/video call records with duration

#### 20. **poll_options**
- Options for polls with vote counts

#### 21. **poll_votes**
- Individual user votes

## Services Layer

### ChatService
Core messaging functionality:
- `getConversations()` - Fetch user's conversations
- `createDirectConversation()` - 1-to-1 chat
- `createGroupConversation()` - Group creation
- `sendMessage()` - Send text/media/contact
- `editMessage()` / `deleteMessage()` - Message editing
- `addReaction()` / `removeReaction()` - Emoji reactions
- `markAsRead()` - Update read receipts
- `getParticipants()` - List conversation members
- `updateParticipantRole()` - Change user role
- `messagesStream()` - Real-time message streaming
- `typingIndicatorStream()` - Real-time typing status
- `setTyping()` - Send typing indicator
- `updateUserPresence()` - Online/offline status
- `getUserPresence()` - Check user status

### PollService
- `createPoll()` - Create poll with options
- `votePoll()` - Cast vote
- `getPoll()` - Fetch poll results
- `closePoll()` - End voting
- `getOptionVoteCount()` - Vote tallying

### TaskService
- `createTask()` - New collaborative task
- `updateTask()` - Modify task details
- `getTasks()` - List tasks for conversation
- `deleteTask()` - Remove task

### AdvancedServices

#### ScheduledMessageService
- `scheduleMessage()` - Queue message for future send
- `cancelScheduledMessage()` - Cancel scheduled message

#### EphemeralMessageService
- `sendEphemeralMessage()` - Send auto-deleting message

#### ConfidentialMessageService
- `sendConfidentialMessage()` - PIN/biometric protected message
- `recordAccess()` - Log who unlocked it

#### MessageReminderService
- `setReminder()` - Snooze on message
- `getReminders()` - Fetch due reminders
- `markAsSent()` - Mark reminder as sent

#### MessageDraftService
- `saveDraft()` - Auto-save draft
- `getDraft()` - Retrieve draft
- `deleteDraft()` - Clear draft

#### BlockedUserService
- `blockUser()` / `unblockUser()` - Manage blocklist
- `getBlockedUsers()` - List blocked users
- `isUserBlocked()` - Check block status

#### ReportedContentService
- `reportContent()` - Flag message or user

#### PinnedMessageService
- `pinMessage()` / `unpinMessage()` - Manage pinned messages
- `getPinnedMessages()` - List pinned messages

### SettingsService

#### ChatSettingsService
- `getSettings()` - Fetch user preferences
- `updateSettings()` - Modify theme, notifications, translation

#### ConversationSettingsService
- `getSettings()` - Fetch conversation customization
- `updateSettings()` - Modify wallpaper, bubble style, encryption
- `toggleMute()` - Do Not Disturb control

## State Management (Riverpod)

### Providers

```dart
// Services
final chatServiceProvider
final pollServiceProvider
final taskServiceProvider

// Conversations
final conversationsProvider                          // List of user's conversations
final conversationByIdProvider                       // Specific conversation

// Messages
final messagesStreamProvider(conversationId)        // Real-time message stream

// Read Receipts & Reactions
final readReceiptsProvider(messageId)               // Message status
final reactionsProvider(messageId)                  // Emoji reactions

// Real-time Status
final typingIndicatorProvider(conversationId)      // Who's typing
final userPresenceProvider(userId)                 // Online/offline

// Groups
final conversationParticipantsProvider(conversationId)  // Group members

// Tasks
final conversationTasksProvider(conversationId)    // Tasks in conversation

// State Notifiers
final selectedConversationProvider                 // Currently selected chat
final typingUsersProvider                          // Cached typing users
```

## UI Components

### MessageBubble
Displays messages with type-specific rendering:
- Text: Plain styled text
- Voice: Play button + waveform + duration
- Video: Thumbnail with play icon
- Image: Image preview
- Document: File icon + metadata
- Contact: Contact card
- Supports reactions display
- Read status indicators
- Edit timestamp

### TypingIndicator
Animated "X is typing..." display with bouncing dots

### OnlineStatusIndicator
Shows user presence (online/offline) with last seen timestamp

### EnhancedMessagesPage
Main chat list featuring:
- Search and filter
- Stats pills (online, new messages, active meetings)
- Online users carousel
- Recent conversations list
- New conversation FAB

### ConversationDetailPage
Full chat view with:
- Real-time message list
- Input area with quick actions
- Emoji picker
- File/media picker
- Message reactions
- Typing indicators
- Online status header

### GroupSettingsPage
Tabbed interface:
- **Discussion**: Message history
- **Members**: Participant list with role management
- **Files**: Shared documents
- **Tasks**: Collaborative tasks

### Dialogs
- PollCreationDialog: Create and configure polls
- TaskCreationDialog: Create collaborative tasks
- EmojiPicker: Select reaction emoji

## Feature Categories

### 1. Messages & Communication
✅ Real-time text messaging
✅ Voice message support (model, service layer ready - UI pending)
✅ Video message support (model, service layer ready - UI pending)
✅ Image & file attachments
✅ Contact sharing
✅ Read receipts (sent/delivered/read)
✅ Typing indicators
✅ Online/offline status + last seen

### 2. Temporary & Scheduled Messages
✅ Database schema and services
⏳ Auto-delete ephemeral messages (background job needed)
⏳ Confidential PIN/biometric messages (biometric auth integration needed)
✅ Scheduled messages with recurrence
✅ Message reminders/snooze

### 3. Interactions & Collaboration
✅ Emoji reactions
✅ Poll creation and voting
✅ Collaborative tasks with assignment/priority
⏳ Slash commands (/poll, /todo, /remind)
⏳ Stories (ephemeral content)

### 4. Security & Privacy
⏳ E2E encryption (requires crypto implementation)
⏳ App PIN lock (requires local_auth integration)
⏳ Conversation PIN lock
⏳ Anti-screenshot detection
⏳ Decoy UI on wrong password
⏳ Remote wipe + location
✅ Session management (model ready)
✅ Block/unblock users
✅ Report content

### 5. Group Management
✅ Role system (admin, moderator, member)
⏳ Waiting room (join approval)
✅ Group settings (name, avatar, description)
✅ Pinned messages
✅ Do Not Disturb (mute duration)

### 6. Personalization & UX
✅ Theme preferences (light/dark/system)
✅ Bubble customization (color, shape, opacity)
✅ Wallpaper per conversation
⏳ Font size adjustment (global)
✅ Custom notification sounds
✅ Auto-save drafts

### 7. Data Management
✅ Archive conversations (model ready - UI pending)
⏳ Export (TXT, JSON, PDF with encryption)
⏳ Advanced search (keywords, date, type, contact)
✅ Offline mode (queue ready - background sync needed)
✅ Data saver (compression settings ready)
⏳ Usage statistics

### 8. Translation & Accessibility
⏳ Auto-translate (OpenAI/DeepL API integration needed)
⏳ Voice transcription + translation

### 9. Audio/Video Calls
⏳ Audio calls (Agora/LiveKit integration needed)
⏳ Video calls
⏳ Call screen (incoming/outgoing)
✅ Call history (model and schema ready)

### 10. Smart Notifications
⏳ Push notifications (FCM integration needed)
✅ Priority modes (all/mentions only/none)
✅ Silent hours
✅ Custom sounds per conversation

## Integration Checklist

### Immediate Dependencies
- [x] flutter_riverpod
- [x] supabase_flutter
- [x] image_picker
- [x] audio_waveforms
- [x] video_player
- [x] uuid
- [x] encrypt

### Needed Dependencies
- [ ] `local_auth` - Already in pubspec (biometric/PIN)
- [ ] `firebase_messaging` - For FCM push notifications
- [ ] `flutter_local_notifications` - For local notifications
- [ ] `share_plus` - For content sharing
- [ ] `pdf` - For PDF export
- [ ] `csv` - For CSV export
- [ ] `open_file` / `file_opener2` - For opening files
- [ ] `flutter_sound` - Enhanced audio support
- [ ] `agora_flutter_sdk` - For video calls
- [ ] `dart_openai` / `deepl` - For translation

### Backend Setup Required
- [ ] Supabase Edge Functions for:
  - [ ] Scheduled message dispatcher
  - [ ] Ephemeral message cleanup
  - [ ] Translation API integration
  - [ ] File compression
  - [ ] Notification delivery
- [ ] Supabase Storage buckets:
  - [ ] `chat-media` - For images, videos, documents

## Usage Examples

### Sending a Message
```dart
final chatService = ref.read(chatServiceProvider);
await chatService.sendMessage(
  conversationId: 'conv-123',
  content: 'Hello!',
  messageType: MessageType.text,
);
```

### Creating a Poll
```dart
final pollService = ref.read(pollServiceProvider);
await pollService.createPoll(
  messageId: 'msg-456',
  question: 'What do you prefer?',
  options: ['Option A', 'Option B', 'Option C'],
  isAnonymous: true,
);
```

### Creating a Task
```dart
final taskService = ref.read(taskServiceProvider);
await taskService.createTask(
  conversationId: 'conv-123',
  title: 'Design homepage',
  description: 'Create new design mockup',
  priority: 'high',
  dueDate: DateTime.now().add(Duration(days: 3)),
);
```

### Monitoring Typing Status
```dart
final typingUsers = ref.watch(typingIndicatorProvider('conv-123'));
typingUsers.whenData((users) {
  // Update UI with typing users
});
```

## Next Steps

1. **Backend Setup**: Deploy Supabase Edge Functions
2. **Integration**: Add remaining dependencies
3. **Features**: Implement pending features
4. **Testing**: Add unit and widget tests
5. **Performance**: Optimize message pagination and caching
6. **Security**: Implement E2E encryption
7. **Analytics**: Add usage tracking
8. **Localization**: Multi-language support

## Notes

- All services use Supabase RLS policies for security
- Real-time subscriptions auto-update UI via Riverpod
- Soft deletes maintain message history
- Optimistic updates improve perceived performance
- Services are stateless and testable
