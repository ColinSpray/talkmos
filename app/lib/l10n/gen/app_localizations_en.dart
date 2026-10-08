// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonAppName => 'Talkmos';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonClose => 'Close';

  @override
  String get commonDone => 'Done';

  @override
  String get commonOk => 'OK';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonSend => 'Send';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonBlock => 'Block';

  @override
  String get commonUnblock => 'Unblock';

  @override
  String get commonMute => 'Mute';

  @override
  String get commonUnmute => 'Unmute';

  @override
  String get commonLeave => 'Leave';

  @override
  String get commonAccept => 'Accept';

  @override
  String get commonDecline => 'Decline';

  @override
  String get commonToday => 'Today';

  @override
  String get commonYesterday => 'Yesterday';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonUnknown => 'Unknown';

  @override
  String get commonMe => 'Me';

  @override
  String get commonYou => 'You';

  @override
  String get commonSettings => 'Settings';

  @override
  String get commonMembers => 'Members';

  @override
  String get commonMember => 'Member';

  @override
  String get commonOpen => 'Open';

  @override
  String get commonAdmin => 'Admin';

  @override
  String get commonAdmins => 'Admins';

  @override
  String get commonEveryone => 'Everyone';

  @override
  String get commonSomeone => 'Someone';

  @override
  String get commonSilent => 'Silent';

  @override
  String get commonUsername => 'Username';

  @override
  String get commonPassword => 'Password';

  @override
  String get commonAbout => 'About';

  @override
  String get commonPermissions => 'Permissions';

  @override
  String get commonMessages => 'Messages';

  @override
  String get commonCalls => 'Calls';

  @override
  String get commonChat => 'Chat';

  @override
  String get commonGallery => 'Gallery';

  @override
  String get commonLocation => 'Location';

  @override
  String get commonVideo => 'Video';

  @override
  String get commonUpdateReady => 'An update is ready to install.';

  @override
  String get commonUpdateRestart => 'Restart';

  @override
  String commonAddedToCall(String name) {
    return 'Adding $name to the call…';
  }

  @override
  String get commonPhoto => 'Photo';

  @override
  String get commonVoiceMessage => 'Voice message';

  @override
  String get commonAudio => 'Audio';

  @override
  String get commonDocument => 'Document';

  @override
  String get commonGif => 'GIF';

  @override
  String get commonSticker => 'Sticker';

  @override
  String get commonFriends => 'Friends';

  @override
  String get commonDevices => 'Devices';

  @override
  String get devicesScreenTitle => 'Devices';

  @override
  String get devicesScreenBannerTitle => 'Keep your account secure';

  @override
  String get devicesScreenBannerMessage =>
      'These are the devices currently signed in to your account. If you see one you don\'t recognize, log it out immediately.';

  @override
  String get devicesScreenThisDevice => 'This device';

  @override
  String get devicesScreenActiveNow => 'Active now';

  @override
  String devicesScreenLastActive(String date) {
    return 'Last active $date';
  }

  @override
  String devicesScreenLoggedOutOn(String date) {
    return 'Logged out $date';
  }

  @override
  String get devicesScreenLogOut => 'Log out';

  @override
  String get devicesScreenLogOutConfirmTitle => 'Log out this device?';

  @override
  String devicesScreenLogOutConfirmMessage(String deviceName) {
    return '$deviceName will be signed out immediately.';
  }

  @override
  String devicesScreenLogOutFailed(String error) {
    return 'Failed to log out device: $error';
  }

  @override
  String get devicesScreenLoggedOut => 'Device logged out';

  @override
  String devicesScreenLoadFailed(String error) {
    return 'Failed to load devices: $error';
  }

  @override
  String get devicesScreenNoDevices => 'No devices found';

  @override
  String get commonAccount => 'Account';

  @override
  String get commonNotifications => 'Notifications';

  @override
  String get commonSpeaker => 'Speaker';

  @override
  String get languageSettingsTitle => 'Language';

  @override
  String get languageSettingsSectionHeader => 'App language';

  @override
  String get languageSettingsFollowDevice => 'Follow device language';

  @override
  String get languageSettingsNoticeTitle => 'Translation notice';

  @override
  String get languageSettingsNoticeBody =>
      'Some newer parts of the app may still show in English until their translations are added.';

  @override
  String get chatScreenGroupDeletedByOwner =>
      'This group was deleted by its owner';

  @override
  String get chatScreenDeleteMessageTitle => 'Delete message?';

  @override
  String chatScreenDeleteMessagesConfirm(int count) {
    return 'Delete $count message(s)?';
  }

  @override
  String chatScreenDeleteMessagesForMeConfirm(int count) {
    return 'Delete $count message(s) for me?';
  }

  @override
  String get chatScreenDeleteForMe => 'Delete for me';

  @override
  String get chatScreenDeleteForEveryone => 'Delete for everyone';

  @override
  String chatScreenDeleteFailed(String error) {
    return 'Failed to delete: $error';
  }

  @override
  String chatScreenCallStartFailed(String error) {
    return 'Failed to start call: $error';
  }

  @override
  String get chatScreenMicPermissionDenied => 'Microphone permission denied';

  @override
  String get chatScreenCallWhileRecording =>
      'Stop the voice recording before starting a call';

  @override
  String get chatScreenRecordWhileInCall => 'You are already on a call';

  @override
  String get chatScreenRecordingStoppedForCall =>
      'Voice recording stopped for the call';

  @override
  String get chatHeaderOnline => 'online';

  @override
  String chatHeaderLastSeenToday(String time) {
    return 'last seen today at $time';
  }

  @override
  String chatHeaderLastSeenYesterday(String time) {
    return 'last seen yesterday at $time';
  }

  @override
  String chatHeaderLastSeenOn(String date, String time) {
    return 'last seen $date at $time';
  }

  @override
  String get chatScreenMessageTooShort => 'Message too short';

  @override
  String chatScreenVoiceSendFailed(String error) {
    return 'Failed to send voice message: $error';
  }

  @override
  String get chatScreenReply => 'Reply';

  @override
  String get chatScreenForward => 'Forward';

  @override
  String get chatScreenCopy => 'Copy';

  @override
  String get chatScreenPin => 'Pin';

  @override
  String get chatScreenUnpin => 'Unpin';

  @override
  String get chatScreenTranslate => 'Translate';

  @override
  String get chatScreenShowOriginal => 'Show Original';

  @override
  String get chatScreenTranslating => 'Translating…';

  @override
  String get chatScreenTranslated => 'Translated';

  @override
  String get chatScreenTranslateFailed =>
      'Couldn\'t translate this message. Check your connection and try again.';

  @override
  String get chatScreenDeleteUnsend => 'Delete / Unsend';

  @override
  String get chatScreenCopiedToClipboard => 'Copied to clipboard';

  @override
  String chatScreenForwardedTo(String name) {
    return 'Forwarded to $name';
  }

  @override
  String get chatScreenUploadingDocument => 'Uploading document...';

  @override
  String chatScreenDocumentUploadFailed(String error) {
    return 'Document upload failed: $error';
  }

  @override
  String get chatScreenContactsPermissionRequired =>
      'Contacts permission is required to share a contact.';

  @override
  String chatScreenShareContactFailed(String error) {
    return 'Could not share contact: $error';
  }

  @override
  String get chatScreenLocationPermissionRequired =>
      'Location permission is required to share your location.';

  @override
  String get chatScreenTurnOnLocationServices =>
      'Turn on location services to share your location.';

  @override
  String get chatScreenGettingLocation => 'Getting your location...';

  @override
  String chatScreenShareLocationFailed(String error) {
    return 'Could not share location: $error';
  }

  @override
  String chatScreenSendingItems(int count) {
    return 'Sending $count item(s)...';
  }

  @override
  String chatScreenMediaUploadFailed(String error) {
    return 'Failed to upload media: $error';
  }

  @override
  String get chatScreenUploadingVideo => 'Uploading video...';

  @override
  String chatScreenVideoUploadFailed(String error) {
    return 'Video upload failed: $error';
  }

  @override
  String chatScreenUploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String chatScreenSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get chatScreenVideoCall => 'Video call';

  @override
  String get chatScreenVoiceCall => 'Voice call';

  @override
  String get chatScreenOriginalMessageSender => 'Original Message';

  @override
  String get chatScreenOriginalMessageNotFound =>
      'Original message not found in history';

  @override
  String get homeScreenTitle => 'Chats';

  @override
  String get homeScreenArchived => 'Archived';

  @override
  String get homeScreenMyStory => 'My Story';

  @override
  String get homeScreenFilterAll => 'All';

  @override
  String get homeScreenFilterUnread => 'Unread';

  @override
  String get homeScreenFilterGroups => 'Groups';

  @override
  String get homeScreenFilterChannels => 'Channels';

  @override
  String get homeScreenFilterBots => 'Bots';

  @override
  String get homeScreenPinChat => 'Pin Chat';

  @override
  String get homeScreenUnpinChat => 'Unpin Chat';

  @override
  String get homeScreenMuteNotifications => 'Mute Notifications';

  @override
  String get homeScreenArchiveChat => 'Archive Chat';

  @override
  String get homeScreenUnarchiveChat => 'Unarchive Chat';

  @override
  String get homeScreenLeaveGroup => 'Leave Group';

  @override
  String get homeScreenBlockContact => 'Block Contact';

  @override
  String get homeScreenUnblockContact => 'Unblock Contact';

  @override
  String get homeScreenDeleteChat => 'Delete Chat';

  @override
  String get homeScreenContactNotIdentified =>
      'Couldn\'t identify this contact';

  @override
  String homeScreenBlockConfirmTitle(String name) {
    return 'Block $name?';
  }

  @override
  String get homeScreenBlockConfirmBody =>
      'They will no longer be able to message or call you, and you won\'t be able to message or call them either.';

  @override
  String homeScreenContactBlocked(String name) {
    return '$name blocked';
  }

  @override
  String homeScreenContactUnblocked(String name) {
    return '$name unblocked';
  }

  @override
  String homeScreenBlockStatusUpdateFailed(String error) {
    return 'Failed to update block status: $error';
  }

  @override
  String homeScreenDeleteChatBody(String name) {
    return 'Delete your chat with $name? It will reappear if a new message arrives.';
  }

  @override
  String homeScreenLeaveGroupBody(String name) {
    return 'Are you sure you want to leave \"$name\"?';
  }

  @override
  String get homeScreenLeaveGroupFailed => 'Failed to leave group';

  @override
  String get homeScreenNoChatsFound => 'No chats found';

  @override
  String get homeScreenNoChatsYet => 'No chats yet';

  @override
  String homeScreenNoConversationsMatch(String query) {
    return 'No conversations match “$query”.';
  }

  @override
  String get homeScreenEmptyStateHint =>
      'Start a conversation or create a group\nto see it here.';

  @override
  String get homeScreenSearchPeople => 'Search people';

  @override
  String get createGroupScreenTitle => 'Create Group';

  @override
  String get createGroupScreenNext => 'Next';

  @override
  String get createGroupScreenNameLabel => 'Group Name';

  @override
  String get createGroupScreenNameHint => 'Enter group name';

  @override
  String get createGroupScreenDescriptionLabel => 'Group Description';

  @override
  String get createGroupScreenOptional => '(Optional)';

  @override
  String get createGroupScreenDescriptionHint =>
      'Tell people what this group is about...';

  @override
  String get createGroupScreenDescriptionHelper =>
      'You can add a description later';

  @override
  String get createGroupScreenUploadingPhoto => 'Uploading…';

  @override
  String get createGroupScreenAddPhoto => 'Add group photo';

  @override
  String get createGroupScreenChangePhoto => 'Change group photo';

  @override
  String createGroupScreenPhotoUploadFailed(String error) {
    return 'Failed to upload photo: $error';
  }

  @override
  String get createGroupScreenEnterName => 'Please enter a group name';

  @override
  String get createGroupScreenSelectAtLeastOneMember =>
      'Select at least 1 member';

  @override
  String createGroupScreenCreateFailed(String error) {
    return 'Failed to create group: $error';
  }

  @override
  String get createGroupScreenSelectMembers => 'Select Members';

  @override
  String get createGroupScreenSelectMembersSubtitle =>
      'Add people you want to add in this group';

  @override
  String createGroupScreenSelectedCount(int count) {
    return '$count Selected';
  }

  @override
  String get createGroupScreenSearchMembersHint =>
      'Search by name, username or Talkmos ID';

  @override
  String get createGroupScreenNoContactsEmpty =>
      'No contacts yet. Add friends to start a group.';

  @override
  String createGroupScreenNoContactsMatch(String query) {
    return 'No contacts match \"$query\".';
  }

  @override
  String createGroupScreenMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Members',
      one: '$count Member',
    );
    return '$_temp0';
  }

  @override
  String get archivedChatsScreenTitle => 'Archived';

  @override
  String get archivedChatsScreenUnarchiveChat => 'Unarchive Chat';

  @override
  String get archivedChatsScreenMuteNotifications => 'Mute Notifications';

  @override
  String get archivedChatsScreenLeaveGroup => 'Leave Group';

  @override
  String get archivedChatsScreenDeleteChat => 'Delete Chat';

  @override
  String archivedChatsScreenDeleteChatBody(String name) {
    return 'Delete your chat with $name? It will reappear if a new message arrives.';
  }

  @override
  String archivedChatsScreenLeaveGroupBody(String name) {
    return 'Are you sure you want to leave \"$name\"?';
  }

  @override
  String get archivedChatsScreenLeaveGroupFailed => 'Failed to leave group';

  @override
  String get archivedChatsScreenEmptyTitle => 'No archived chats';

  @override
  String get archivedChatsScreenEmptyBody =>
      'Chats you archive will show up here and stay out of your main list.';

  @override
  String get groupProfileScreenFailedToLoad => 'Failed to load group details';

  @override
  String get groupProfileScreenImageUpdated =>
      'Group image updated successfully!';

  @override
  String groupProfileScreenUploadFailed(String error) {
    return 'Failed to upload group photo: $error';
  }

  @override
  String get groupProfileScreenDescriptionUpdated =>
      'Group description updated';

  @override
  String get groupProfileScreenDescriptionUpdateFailed =>
      'Failed to update description';

  @override
  String get groupProfileScreenNameUpdated => 'Group name updated';

  @override
  String get groupProfileScreenNameUpdateFailed => 'Failed to update name';

  @override
  String get groupProfileScreenLeaveGroup => 'Leave Group';

  @override
  String get groupProfileScreenLeaveGroupConfirm =>
      'Are you sure you want to leave this group?';

  @override
  String get groupProfileScreenLeaveFailed => 'Failed to leave group';

  @override
  String get groupProfileScreenDeleteGroup => 'Delete Group';

  @override
  String get groupProfileScreenDeleteGroupConfirm =>
      'This deletes the group for everyone, including its messages. This cannot be undone.';

  @override
  String get groupProfileScreenDeleteFailed => 'Failed to delete group';

  @override
  String get groupProfileScreenGroupDeleted => 'Group deleted';

  @override
  String get groupProfileScreenRemoveMemberTitle => 'Remove Member';

  @override
  String groupProfileScreenRemoveMemberBody(String name) {
    return 'Remove $name from the group?';
  }

  @override
  String groupProfileScreenMemberRemoved(String name) {
    return '$name removed';
  }

  @override
  String get groupProfileScreenRemoveMemberFailed => 'Failed to remove member';

  @override
  String get groupProfileScreenAddMembersTitle => 'Add Members';

  @override
  String groupProfileScreenAddButtonLabel(int count) {
    return 'Add ($count)';
  }

  @override
  String groupProfileScreenMembersAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count members',
      one: 'Added $count member',
    );
    return '$_temp0';
  }

  @override
  String groupProfileScreenAddMembersFailed(String error) {
    return 'Failed to add members: $error';
  }

  @override
  String get groupProfileScreenNoMoreContacts => 'No more contacts to add';

  @override
  String get groupProfileScreenTitle => 'Group Settings';

  @override
  String get groupProfileScreenInviteMembers => 'Invite Members';

  @override
  String get groupProfileScreenPrivacy => 'Privacy';

  @override
  String get groupProfileScreenEditGroupInfo => 'Edit Group Info';

  @override
  String get groupProfileScreenMediaVisibility => 'Media Visibility';

  @override
  String get groupProfileScreenMuteNotifications => 'Mute Notifications';

  @override
  String get groupProfileScreenDangerZone => 'Danger Zone';

  @override
  String groupProfileScreenMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Members',
      one: '$count Member',
    );
    return '$_temp0';
  }

  @override
  String groupProfileScreenMembersCountTitle(int count) {
    return 'Members ($count)';
  }

  @override
  String get groupProfileScreenNoAdminsYet => 'No admins yet.';

  @override
  String get groupProfileScreenNoMembersYet => 'No members yet.';

  @override
  String get groupProfileScreenOwnerRole => 'Owner';

  @override
  String get groupProfileScreenGroupNameLabel => 'Group name';

  @override
  String get groupProfileScreenDescriptionLabel => 'Description';

  @override
  String get mediaPreviewScreenAddTextLabelTitle => 'Add Text Label';

  @override
  String get mediaPreviewScreenTypeTextHint => 'Type text here...';

  @override
  String mediaPreviewScreenFileSize(String size) {
    return '$size';
  }

  @override
  String get mediaPreviewScreenCropImageTooltip => 'Crop Image';

  @override
  String get mediaPreviewScreenRotateImageTooltip => 'Rotate Image';

  @override
  String get mediaPreviewScreenAddTextTooltip => 'Add Text';

  @override
  String get mediaPreviewScreenDrawDoodleTooltip => 'Draw Doodle';

  @override
  String get mediaPreviewScreenUndoStrokeTooltip => 'Undo last stroke';

  @override
  String get mediaPreviewScreenCaptionHint => 'Add a caption…';

  @override
  String get groupPermissionsScreenSendMessagesLabel => 'Send Messages';

  @override
  String get groupPermissionsScreenSendMessagesDescription =>
      'Who can post in this group';

  @override
  String get groupPermissionsScreenEditInfoLabel => 'Edit Group Info';

  @override
  String get groupPermissionsScreenEditInfoDescription =>
      'Who can change the name, photo and description';

  @override
  String get groupPermissionsScreenAddMembersLabel => 'Add Members';

  @override
  String get groupPermissionsScreenAddMembersDescription =>
      'Who can invite people into this group';

  @override
  String get groupPermissionsScreenAdminOnlyNotice =>
      'Only group admins can change these settings.';

  @override
  String get groupPermissionsScreenAllMembers => 'All members';

  @override
  String get groupPermissionsScreenOnlyAdmins => 'Only admins';

  @override
  String groupPermissionsScreenUpdateFailed(String error) {
    return 'Could not update: $error';
  }

  @override
  String get videoPlayerScreenLoadFailed => 'Failed to load video';

  @override
  String get sharedMediaScreenTitle => 'Shared Media';

  @override
  String get sharedMediaScreenLoadFailed => 'Could not load shared media';

  @override
  String get sharedMediaScreenEmptyTitle => 'No media shared yet';

  @override
  String get sharedMediaScreenEmptyBody =>
      'Photos and videos you send or receive\nhere will show up in this gallery.';

  @override
  String get imageViewerLoadFailed => 'Failed to load image';

  @override
  String get chatBubbleEdited => 'Edited';

  @override
  String get chatBubbleReadMore => 'Read more';

  @override
  String get chatBubbleReadLess => 'Read less';

  @override
  String get chatInputBarEditMessage => 'Edit message';

  @override
  String get chatInputBarHint => 'Type a message…';

  @override
  String get chatHeaderTypingLabel => 'typing';

  @override
  String get contextActionMenuActionsLabel => 'Actions';

  @override
  String get chatBodyPrivacyBanner => 'Messages are private to this chat.';

  @override
  String chatBodyYouBlocked(String peerName) {
    return 'You blocked $peerName';
  }

  @override
  String get chatBodyNoMessagesYet => 'No messages yet';

  @override
  String chatBodySayHi(String name) {
    return 'Say hi to $name to start the conversation.';
  }

  @override
  String recentChatTileContactWithName(String name) {
    return 'Contact: $name';
  }

  @override
  String get recentChatTileContact => 'Contact';

  @override
  String get recentChatTileTapToOpen => 'Tap to open conversation';

  @override
  String get mediaVisibilityPermissionNeeded =>
      'Talkmos needs permission to add to your gallery. You can grant it in system settings.';

  @override
  String get mediaVisibilitySheetTitle => 'Media visibility';

  @override
  String get mediaVisibilitySheetDescription =>
      'Whether photos and videos from this chat are saved to this device\'s gallery.';

  @override
  String get mediaVisibilitySheetFollowsGlobal =>
      'Follows the global Save to Photos setting';

  @override
  String get wallpaperPickerNone => 'None';

  @override
  String get attachmentSheetDocument => 'Document';

  @override
  String get attachmentSheetCamera => 'Camera';

  @override
  String get attachmentSheetContact => 'Contact';

  @override
  String get forwardMessageSheetTitle => 'Forward to';

  @override
  String get forwardMessageSheetNoChats => 'No chats available';

  @override
  String get pinnedMessageBannerTitle => 'Pinned Message';

  @override
  String get pinnedMessageBannerConfirmTitle => 'Unpin message?';

  @override
  String get pinnedMessageBannerConfirmBody =>
      'Are you sure you want to unpin this message?';

  @override
  String get pinnedMessageBannerUnpinAction => 'Unpin';

  @override
  String wizardStepHeaderStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get deletedMessageBody => 'This message was deleted';

  @override
  String get voiceMessageFailedToPlay => 'Failed to play audio';

  @override
  String get imageMessageFailedToLoad => 'Failed to load image';

  @override
  String get locationMessageCurrentLocation => 'Current Location';

  @override
  String get documentMessageDefaultName => 'Document';

  @override
  String get documentMessageFileExtensionFallback => 'FILE';

  @override
  String documentMessageOpenFailed(String reason) {
    return 'Could not open file: $reason';
  }

  @override
  String get documentMessageDownloadFailed => 'Could not download file';

  @override
  String get documentMessagePageCountOne => '1 page';

  @override
  String documentMessagePageCount(int count) {
    return '$count pages';
  }

  @override
  String get completeProfileScreenTitle => 'Complete your profile';

  @override
  String get completeProfileScreenSubtitle =>
      'Tell us who you are so friends can find you.';

  @override
  String get completeProfileScreenFullName => 'Full name';

  @override
  String get completeProfileScreenFullNameHint => 'e.g. Alex Morgan';

  @override
  String get completeProfileScreenNameRequired => 'Please enter your name';

  @override
  String get completeProfileScreenUsernameHint => 'e.g. alexmorgan';

  @override
  String get completeProfileScreenUsernameMinLength => 'At least 3 characters';

  @override
  String get completeProfileScreenFinish => 'Finish';

  @override
  String get phoneLoginScreenSelectCountryCode => 'Select Country Code';

  @override
  String get phoneLoginScreenInvalidPhone =>
      'Please enter a valid 10-digit phone number';

  @override
  String get phoneLoginScreenSubtitle => 'Login or register to start chatting';

  @override
  String get phoneLoginScreenPhoneNumberLabel => 'Phone Number';

  @override
  String get phoneLoginScreenContinueWithApple => 'Continue with Apple';

  @override
  String get phoneLoginScreenAppleComingSoon => 'Apple sign-in coming soon';

  @override
  String get phoneLoginScreenContinueWithGoogle => 'Continue with Google';

  @override
  String get phoneLoginScreenPhoneHint => 'Enter phone number';

  @override
  String get phoneLoginScreenContinue => 'Continue';

  @override
  String get phoneLoginScreenVerificationNote =>
      'We will send you a verification code\nto confirm your number';

  @override
  String get phoneLoginScreenOr => 'or';

  @override
  String get phoneLoginScreenAgreeTerms => 'By continuing, you agree to our';

  @override
  String get phoneLoginScreenTermsOfService => 'Terms of Service';

  @override
  String get phoneLoginScreenAnd => ' and ';

  @override
  String get phoneLoginScreenPrivacyPolicy => 'Privacy Policy';

  @override
  String get phoneConfirmationScreenSelectCountryCode => 'Select Country Code';

  @override
  String get phoneConfirmationScreenInvalidPhone =>
      'Please enter a valid 10-digit phone number';

  @override
  String get phoneConfirmationScreenPhoneHint => 'Enter phone number';

  @override
  String get phoneConfirmationScreenTitle => 'Confirm Your Phone Number';

  @override
  String get phoneConfirmationScreenSubtitle =>
      'To keep your account secure and connect with your contacts, please enter your mobile number.';

  @override
  String get phoneConfirmationScreenConfirmContinue => 'Confirm & Continue';

  @override
  String get otpVerificationScreenEnterCode => 'Enter the verification code';

  @override
  String get otpVerificationScreenCodeResent => 'Code resent successfully';

  @override
  String get otpVerificationScreenReceivedOtp => 'Received OTP from Backend';

  @override
  String get otpVerificationScreenOtpFilled => 'OTP filled into text field';

  @override
  String get otpVerificationScreenDirectOtpNote =>
      'Direct OTP from server • Tap code to re-fill';

  @override
  String get otpVerificationScreenTitle => 'Verify your number';

  @override
  String otpVerificationScreenSentTo(String phone) {
    return 'Enter the 6-digit code sent to $phone';
  }

  @override
  String get otpVerificationScreenVerify => 'Verify';

  @override
  String get otpVerificationScreenDidntGetCode => 'Didn\'t get the code? ';

  @override
  String get otpVerificationScreenSending => 'Sending…';

  @override
  String get otpVerificationScreenResend => 'Resend';

  @override
  String get registerScreenAccountCreated => 'Account created successfully!';

  @override
  String get registerScreenCreateYourPrefix => 'Create your ';

  @override
  String get registerScreenAccountWord => 'account';

  @override
  String get registerScreenSubtitle =>
      'Join Talkmos and start connecting with your team and community.';

  @override
  String get registerScreenFullName => 'Full Name';

  @override
  String get registerScreenFullNameHint => 'Enter your full name';

  @override
  String get registerScreenNameRequired => 'Name is required';

  @override
  String get registerScreenEmailAddress => 'Email Address';

  @override
  String get registerScreenEmailHint => 'Enter your email address';

  @override
  String get registerScreenEmailRequired => 'Email is required';

  @override
  String get registerScreenEmailInvalid => 'Enter a valid email address';

  @override
  String get registerScreenPasswordHint => 'Enter password';

  @override
  String get registerScreenPasswordRequired => 'Password is required';

  @override
  String get registerScreenPasswordMinLength =>
      'Password must be at least 6 characters';

  @override
  String get registerScreenConfirmPassword => 'Confirm Password';

  @override
  String get registerScreenConfirmPasswordHint => 'Confirm password';

  @override
  String get registerScreenConfirmPasswordRequired =>
      'Confirm password is required';

  @override
  String get registerScreenPasswordsMismatch => 'Passwords do not match';

  @override
  String get registerScreenSignUp => 'Sign Up';

  @override
  String get registerScreenOrContinueWith => 'Or continue with';

  @override
  String get registerScreenSignInWithGoogle => 'Sign In with Google';

  @override
  String get registerScreenAlreadyHaveAccount => 'Already have an account? ';

  @override
  String get registerScreenSignIn => 'Sign In';

  @override
  String get loginScreenWelcomeBackTo => 'Welcome back to ';

  @override
  String get loginScreenSubtitle =>
      'Log in to connect with your team and access your community.';

  @override
  String get loginScreenPhoneOrUsername => 'Phone or Username';

  @override
  String get loginScreenPhoneOrUsernameHint => '+1234567890 or username';

  @override
  String get loginScreenPhoneOrUsernameRequired =>
      'Phone or username is required';

  @override
  String get loginScreenPasswordHint => 'Enter password';

  @override
  String get loginScreenPasswordRequired => 'Password is required';

  @override
  String get loginScreenForgotPassword => 'Forgot password?';

  @override
  String get loginScreenSignIn => 'Sign In';

  @override
  String get loginScreenOrContinueWith => 'Or continue with';

  @override
  String get loginScreenSignInWithGoogle => 'Sign In with Google';

  @override
  String get loginScreenSignInWithPhoneOtp => 'Sign In with Phone OTP';

  @override
  String get loginScreenDontHaveAccount => 'Don\'t have an account? ';

  @override
  String get loginScreenSignUp => 'Sign Up';

  @override
  String get welcomeScreenTagline => 'Chat. Meet. Collaborate.';

  @override
  String get welcomeScreenDescription =>
      'All-in-one communication platform for chats, calls, smart meetings & communities.';

  @override
  String get welcomeScreenLetsStart => 'Let\'s Start';

  @override
  String get forgotPasswordScreenEmailRequired =>
      'Please enter your email or phone number.';

  @override
  String get forgotPasswordScreenCodeResent => 'A new code has been sent.';

  @override
  String get forgotPasswordScreenIncompleteCode =>
      'Please enter the full 6-digit code.';

  @override
  String get forgotPasswordScreenPasswordMinLength =>
      'Password must be at least 8 characters.';

  @override
  String get forgotPasswordScreenPasswordsMismatch => 'Passwords do not match.';

  @override
  String get forgotPasswordScreenTitleEmail => 'Forgot Password';

  @override
  String get forgotPasswordScreenTitleOtp => 'Enter Verification Code';

  @override
  String get forgotPasswordScreenTitleNewPassword => 'Set New Password';

  @override
  String get forgotPasswordScreenSubtitleEmail =>
      'Enter your email or phone and we\'ll send you a verification code.';

  @override
  String get forgotPasswordScreenSubtitleOtp =>
      'Check your inbox or messages for the 6-digit code we sent.';

  @override
  String get forgotPasswordScreenSubtitleNewPassword =>
      'Choose a strong password you haven\'t used before.';

  @override
  String get forgotPasswordScreenEmailOrPhoneLabel => 'Email or Phone Number';

  @override
  String get forgotPasswordScreenEmailOrPhoneHint =>
      'name@example.com or +91...';

  @override
  String get forgotPasswordScreenSendCode => 'Send Code';

  @override
  String forgotPasswordScreenCodeSentTo(String email) {
    return 'Code sent to $email';
  }

  @override
  String get forgotPasswordScreenVerifyCode => 'Verify Code';

  @override
  String get forgotPasswordScreenDidntReceiveCode => 'Didn\'t receive a code? ';

  @override
  String get forgotPasswordScreenResend => 'Resend';

  @override
  String get forgotPasswordScreenNewPasswordLabel => 'New Password';

  @override
  String get forgotPasswordScreenAtLeast8Chars => 'At least 8 characters';

  @override
  String get forgotPasswordScreenConfirmPasswordLabel => 'Confirm Password';

  @override
  String get forgotPasswordScreenReenterPassword => 'Re-enter your password';

  @override
  String get forgotPasswordScreenResetPassword => 'Reset Password';

  @override
  String get forgotPasswordScreenChars8Plus => '8+ chars';

  @override
  String get forgotPasswordScreenUppercase => 'Uppercase';

  @override
  String get forgotPasswordScreenNumber => 'Number';

  @override
  String get forgotPasswordScreenSuccessTitle => 'Password Reset!';

  @override
  String get forgotPasswordScreenSuccessMessage =>
      'Your password has been successfully updated.\nYou can now log in with your new password.';

  @override
  String get forgotPasswordScreenBackToLogin => 'Back to Login';

  @override
  String get editProfileScreenUpdateSuccess => 'Profile updated successfully!';

  @override
  String editProfileScreenUploadPhotoFailed(String error) {
    return 'Failed to upload photo: $error';
  }

  @override
  String get editProfileScreenChangePhotoTitle => 'Change Profile Photo';

  @override
  String get editProfileScreenChoosePhotoSubtitle =>
      'Choose a photo to represent you';

  @override
  String get editProfileScreenCameraLabel => 'Camera';

  @override
  String get editProfileScreenTakePhotoSubtitle => 'Take a photo';

  @override
  String get editProfileScreenPickFromLibrarySubtitle => 'Pick from library';

  @override
  String get editProfileScreenRemoveCurrentPhoto => 'Remove current photo';

  @override
  String get editProfileScreenTitle => 'Edit Profile';

  @override
  String get editProfileScreenBasicInfo => 'Basic Info';

  @override
  String get editProfileScreenFullName => 'Full Name';

  @override
  String get editProfileScreenFullNameHint => 'Your display name';

  @override
  String get editProfileScreenNameEmptyError => 'Name cannot be empty';

  @override
  String get editProfileScreenUsernameHint =>
      'Unique handle others can find you by';

  @override
  String get editProfileScreenBio => 'Bio';

  @override
  String get editProfileScreenBioHint => 'A short line about you';

  @override
  String get editProfileScreenLocationHint => 'Where you are';

  @override
  String get editProfileScreenEmail => 'Email';

  @override
  String get editProfileScreenPhone => 'Phone';

  @override
  String get editProfileScreenEmailPhoneNotice =>
      'Email and phone are tied to your sign-in and can\'t be edited here.';

  @override
  String get editProfileScreenSaveChanges => 'Save Changes';

  @override
  String get editProfileScreenUploading => 'Uploading…';

  @override
  String get editProfileScreenChangePhoto => 'Change photo';

  @override
  String get appearanceSettingsScreenTitle => 'Appearance';

  @override
  String get appearanceSettingsScreenInterfaceTheme => 'Interface Theme';

  @override
  String get appearanceSettingsScreenBrandPrimaryColor => 'Brand Primary Color';

  @override
  String get appearanceSettingsScreenBrandColorDesc =>
      'Changes the highlights and action buttons across the app.';

  @override
  String get appearanceSettingsScreenChatWallpaperStyle =>
      'Chat Wallpaper & Style';

  @override
  String get appearanceSettingsScreenColorBackdrop => 'Color Backdrop';

  @override
  String get appearanceSettingsScreenBackgroundDoodles => 'Background Doodles';

  @override
  String get appearanceSettingsScreenBackgroundDoodlesDesc =>
      'Add subtle illustrations to flat colors.';

  @override
  String get appearanceSettingsScreenWallpaperGallery => 'Wallpaper Gallery';

  @override
  String get appearanceSettingsScreenThemeLight => 'Light';

  @override
  String get appearanceSettingsScreenThemeDark => 'Dark';

  @override
  String get appearanceSettingsScreenThemeSystem => 'System';

  @override
  String get appearanceSettingsScreenImageOpacity => 'Image Opacity';

  @override
  String get privacySettingsScreenTitle => 'Privacy & Security';

  @override
  String get privacySettingsScreenPrivateAccountTitle => 'Private account';

  @override
  String get privacySettingsScreenPrivateAccountDescPrivate =>
      'Your account is Private. People who aren\'t your contacts have to send you a friend request before they can message you, call you, or see your stories.';

  @override
  String get privacySettingsScreenPrivateAccountDescPublic =>
      'Your account is Public. Anyone on Talkmos can message you, call you, and see your stories.';

  @override
  String get privacySettingsScreenPrivacyControls => 'Privacy Controls';

  @override
  String get privacySettingsScreenReadReceipts => 'Read Receipts';

  @override
  String get privacySettingsScreenReadReceiptsDesc =>
      'Let others know when you\'ve read their messages.';

  @override
  String get privacySettingsScreenLastSeenOnline => 'Last Seen & Online';

  @override
  String get privacySettingsScreenLastSeenSheetTitle =>
      'Who can see my last seen';

  @override
  String get privacySettingsScreenProfilePhotoTitle => 'Profile Photo';

  @override
  String get privacySettingsScreenProfilePhotoSheetTitle =>
      'Who can see my profile photo';

  @override
  String get privacySettingsScreenMedia => 'Media';

  @override
  String get privacySettingsScreenSaveToPhotos => 'Save to Photos';

  @override
  String get privacySettingsScreenSaveToPhotosDesc =>
      'Save photos and videos you receive to this device\'s gallery, where other apps can see them. Off by default. Individual chats can override this.';

  @override
  String get privacySettingsScreenBlockedContacts => 'Blocked Contacts';

  @override
  String get privacySettingsScreenBlockedCountNone => 'None';

  @override
  String privacySettingsScreenBlockedCount(int count) {
    return '$count blocked';
  }

  @override
  String get privacySettingsScreenLegalPolicy => 'Legal & Policy';

  @override
  String get privacySettingsScreenPrivacyPolicy => 'Privacy Policy';

  @override
  String get privacySettingsScreenPrivacyPolicyDesc =>
      'How your data is handled';

  @override
  String get privacySettingsScreenTermsOfService => 'Terms of Service';

  @override
  String get privacySettingsScreenTermsDesc =>
      'The agreement you accepted at sign-up';

  @override
  String get privacySettingsScreenGalleryPermissionNeeded =>
      'Talkmos needs permission to add to your gallery. You can grant it in system settings.';

  @override
  String get privacySettingsScreenSyncError =>
      'Couldn\'t save that setting. Check your connection.';

  @override
  String get privacySettingsScreenBrowserOpenError =>
      'Couldn\'t open the browser.';

  @override
  String get privacySettingsScreenConnectionSecured =>
      'Your connection is secured';

  @override
  String get privacySettingsScreenConnectionSecuredDesc =>
      'Messages and calls travel over an encrypted connection, and only people in a chat can open it. Messages cached on this device are encrypted at rest.';

  @override
  String get profileScreenCheckingForUpdates => 'Checking for app updates...';

  @override
  String profileScreenLatestVersion(String appName) {
    return 'You are on the latest version of $appName!';
  }

  @override
  String profileScreenComingSoon(String feature) {
    return '$feature coming soon!';
  }

  @override
  String get profileScreenPrivacySecurity => 'Privacy & Security';

  @override
  String get profileScreenDataAndStorage => 'Data and Storage';

  @override
  String get profileScreenChatSettings => 'Chat Settings';

  @override
  String get profileScreenLanguage => 'Language';

  @override
  String get profileScreenHelpSupport => 'Help & Support';

  @override
  String get profileScreenCheckForUpdates => 'Check for Updates';

  @override
  String get profileScreenLogOut => 'Log Out';

  @override
  String get profileScreenUserFallback => 'User';

  @override
  String get profileScreenAccountDesc => 'Manage your profile details';

  @override
  String get profileScreenPrivacySecurityDesc =>
      'Control who can see your info';

  @override
  String get profileScreenNotificationsDesc => 'Message, group and call alerts';

  @override
  String get profileScreenDataAndStorageDesc =>
      'Manage storage and media usage';

  @override
  String get profileScreenChatSettingsDesc =>
      'Wallpaper, themes and chat appearance';

  @override
  String get profileScreenDevicesDesc => 'Manage where you\'re logged in';

  @override
  String get profileScreenLanguageDesc => 'Change the app\'s language';

  @override
  String get profileScreenCheckForUpdatesDesc =>
      'Check if a new version is available';

  @override
  String get profileScreenAboutDesc => 'App info and legal details';

  @override
  String get aboutScreenTitle => 'About';

  @override
  String aboutScreenVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutScreenLegalSectionTitle => 'Legal';

  @override
  String get aboutScreenTermsOfService => 'Terms of Service';

  @override
  String get aboutScreenPrivacyPolicy => 'Privacy Policy';

  @override
  String get aboutScreenHelpSupportDesc => 'Get help or contact us';

  @override
  String get aboutScreenBrowserOpenError =>
      'Couldn\'t open the browser. Please try again.';

  @override
  String aboutScreenCopyright(String year, String appName) {
    return '© $year $appName. All rights reserved.';
  }

  @override
  String get dataStorageSettingsScreenTitle => 'Data and Storage';

  @override
  String get dataStorageSettingsScreenStorageHeader => 'Storage';

  @override
  String get dataStorageSettingsScreenCachedMedia => 'Cached media';

  @override
  String get dataStorageSettingsScreenClearing => 'Clearing…';

  @override
  String get dataStorageSettingsScreenTapToClear => 'Tap to clear';

  @override
  String get dataStorageSettingsScreenMeasuring => 'Measuring…';

  @override
  String get dataStorageSettingsScreenClearingSafeTitle => 'Clearing is safe';

  @override
  String get dataStorageSettingsScreenClearingSafeDesc =>
      'Photos, videos and voice notes are re-downloaded from the server when you open them again. Your messages are stored separately and are never removed by this.';

  @override
  String get dataStorageSettingsScreenMediaUpload => 'Media Upload';

  @override
  String get dataStorageSettingsScreenUploadQuality => 'Upload quality';

  @override
  String get dataStorageSettingsScreenAutomaticDownloads =>
      'Automatic Downloads';

  @override
  String get dataStorageSettingsScreenAutoSaveWifiOnly =>
      'Auto-save over Wi-Fi only';

  @override
  String get dataStorageSettingsScreenAutoSaveWifiOnlyDesc =>
      'Wait for Wi-Fi before saving received media to your gallery. Media you open is always downloaded, on any connection.';

  @override
  String get dataStorageSettingsScreenSaveToPhotos => 'Save to Photos';

  @override
  String get dataStorageSettingsScreenOn => 'On';

  @override
  String get dataStorageSettingsScreenOff => 'Off';

  @override
  String get dataStorageSettingsScreenNothingAutoSavedTitle =>
      'Nothing is being auto-saved';

  @override
  String get dataStorageSettingsScreenNothingAutoSavedDesc =>
      'Save to Photos is off, so received media stays inside Talkmos and the Wi-Fi setting above has nothing to do yet. Individual chats can still opt in from their info page.';

  @override
  String get dataStorageSettingsScreenPhotoUploadQualityTitle =>
      'Photo upload quality';

  @override
  String get dataStorageSettingsScreenRecommended => 'Recommended';

  @override
  String get dataStorageSettingsScreenQualityDataSaverDesc =>
      'Smallest files, softest detail';

  @override
  String get dataStorageSettingsScreenQualityStandardDesc =>
      'Balanced — what Talkmos has always sent';

  @override
  String get dataStorageSettingsScreenQualityHighDesc =>
      'Sharpest detail, largest files';

  @override
  String get dataStorageSettingsScreenClearCacheTitle => 'Clear cached media?';

  @override
  String dataStorageSettingsScreenClearCacheDesc(String size) {
    return 'This frees up the space cached media is using$size. Photos, videos and voice notes will be downloaded again the next time you open them. Your messages are not affected.';
  }

  @override
  String get dataStorageSettingsScreenClear => 'Clear';

  @override
  String get dataStorageSettingsScreenCacheCleared => 'Cached media cleared';

  @override
  String get helpSupportScreenFaq1Question =>
      'How do I pin or unpin conversations?';

  @override
  String get helpSupportScreenFaq1Answer =>
      'Go to the recent chat list on the Home screen. Long press on any conversation card and select \'Pin Conversation\' or \'Unpin Conversation\' from the pop-up options sheet. Pinned chats stay anchored at the top of your list.';

  @override
  String get helpSupportScreenFaq2Question =>
      'How do I record and send audio voice messages?';

  @override
  String get helpSupportScreenFaq2Answer =>
      'Open any chat room. Tap and hold the mic icon in the message bar to record a voice note. The bar will show a recording duration and a cancel trigger. Releasing/sending will direct you to a premium preview page where you can review your WAV recording before sharing it.';

  @override
  String get helpSupportScreenFaq3Question =>
      'Where can I change the chat wallpaper backgrounds?';

  @override
  String get helpSupportScreenFaq3Answer =>
      'Navigate to your Profile tab, tap \'Appearance\', and open the Chat Wallpaper customize panel. You can select custom solid backdrop colors or toggle background doodles on and off.';

  @override
  String get helpSupportScreenFaq4Question =>
      'How does message pinning work inside chat rooms?';

  @override
  String get helpSupportScreenFaq4Answer =>
      'Inside any chat thread, single-tap a message bubble to view details and tap the Pin button in the AppBar. Pinned messages appear in a floating banner at the top of the chat room. Tapping it automatically scrolls you directly to that message.';

  @override
  String get helpSupportScreenTicketSubmittedTitle => 'Ticket Submitted';

  @override
  String get helpSupportScreenTicketSubmittedBody =>
      'Thank you for contacting Talkmos support. Your message has been sent successfully. Our team will review your report and respond shortly.';

  @override
  String get helpSupportScreenTitle => 'Help & Support';

  @override
  String get helpSupportScreenFaqHeading => 'Frequently Asked Questions';

  @override
  String get helpSupportScreenSubmitTicketHeading => 'Submit a Support Ticket';

  @override
  String get helpSupportScreenSubjectLabel => 'Subject';

  @override
  String get helpSupportScreenSubjectHint => 'e.g. Bug report, audio error';

  @override
  String get helpSupportScreenSubjectRequired => 'Please enter a subject';

  @override
  String get helpSupportScreenDescriptionLabel => 'Description / Message';

  @override
  String get helpSupportScreenDescriptionHint =>
      'Tell us how we can help you...';

  @override
  String get helpSupportScreenDescriptionRequired =>
      'Please describe your request';

  @override
  String get helpSupportScreenSubmitButton => 'Submit Ticket';

  @override
  String get notificationsSettingsScreenAlertChannels => 'Alert Channels';

  @override
  String get notificationsSettingsScreenReceiveNotifications =>
      'Receive Notifications';

  @override
  String get notificationsSettingsScreenReceiveNotificationsDesc =>
      'Get instant alerts for messages and updates.';

  @override
  String get notificationsSettingsScreenMessageSound => 'Message Sound';

  @override
  String get notificationsSettingsScreenVibrationAlerts => 'Vibration Alerts';

  @override
  String get notificationsSettingsScreenVibrationAlertsDesc =>
      'Haptic feedback on every alert.';

  @override
  String get notificationsSettingsScreenMessagePreviews => 'Message Previews';

  @override
  String get notificationsSettingsScreenMessagePreviewsDesc =>
      'Show content on the lock screen.';

  @override
  String get notificationsSettingsScreenCallRingtone => 'Call Ringtone';

  @override
  String get notificationsSettingsScreenAudioToneNoticeTitle =>
      'Audio Tone Notice';

  @override
  String get notificationsSettingsScreenAudioToneNoticeDesc =>
      'Ringtone changes take effect on the next incoming call. Some tones may sound different depending on your device.';

  @override
  String get notificationsSettingsScreenPrivateByDefaultTitle =>
      'Private by default';

  @override
  String get notificationsSettingsScreenPrivateByDefaultDesc =>
      'Only people in a chat can read its messages.';

  @override
  String get blockedContactsScreenTitle => 'Blocked Contacts';

  @override
  String blockedContactsScreenUnblockConfirmTitle(String name) {
    return 'Unblock $name?';
  }

  @override
  String get blockedContactsScreenUnblockConfirmBody =>
      'You will be able to message and call each other again.';

  @override
  String blockedContactsScreenUnblockFailed(String error) {
    return 'Failed to unblock: $error';
  }

  @override
  String get blockedContactsScreenEmptyTitle => 'No blocked contacts';

  @override
  String get blockedContactsScreenEmptyDesc =>
      'People you block will no longer be able to message or call you.';

  @override
  String get selectContactScreenSearchHint =>
      'Search name, username or phone...';

  @override
  String get selectContactScreenTitle => 'Select contact';

  @override
  String get selectContactScreenLoadingContacts => 'Loading contacts...';

  @override
  String selectContactScreenContactCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contacts',
      one: '$count contact',
    );
    return '$_temp0';
  }

  @override
  String get selectContactScreenNewGroup => 'New group';

  @override
  String get selectContactScreenNewGroupSubtitle => 'Create a new group chat';

  @override
  String get selectContactScreenNewContact => 'New contact';

  @override
  String get selectContactScreenNewContactSubtitle =>
      'Add a friend or find users';

  @override
  String get selectContactScreenContactsOnTalkmos => 'Contacts on Talkmos';

  @override
  String get selectContactScreenFindContactsOnTalkmos =>
      'Find contacts on Talkmos';

  @override
  String get selectContactScreenPermissionDeniedMessage =>
      'Contacts permission is off, so we can\'t show who you already know on Talkmos.';

  @override
  String get selectContactScreenTryAgain => 'Try again';

  @override
  String get selectContactScreenNoMatchingContacts => 'No matching contacts';

  @override
  String get selectContactScreenNothingToShowYet => 'Nothing to show yet';

  @override
  String selectContactScreenNoPhoneContactsMatch(String query) {
    return 'No phone contacts match \"$query\".';
  }

  @override
  String get selectContactScreenIndianNumbersOnly =>
      'We only list Indian mobile numbers saved on this phone. Save a contact, then refresh to see them here.';

  @override
  String get selectContactScreenClearSearch => 'Clear search';

  @override
  String get selectContactScreenRefreshContacts => 'Refresh contacts';

  @override
  String get selectContactScreenFromYourContacts => 'FROM YOUR CONTACTS';

  @override
  String get selectContactScreenInvite => 'Invite';

  @override
  String get selectContactScreenAddFriendTooltip => 'Add friend';

  @override
  String get selectContactScreenRequested => 'Requested';

  @override
  String get selectContactScreenWantsToConnect => 'Wants to connect';

  @override
  String selectContactScreenCouldNotOpenChat(String error) {
    return 'Could not open chat: $error';
  }

  @override
  String get selectContactScreenFriendRequestSent => 'Friend request sent';

  @override
  String selectContactScreenCouldNotSendRequest(String error) {
    return 'Could not send request: $error';
  }

  @override
  String get selectContactScreenInviteMessage =>
      'Join me on Talkmos — https://talkmos.com';

  @override
  String get selectContactScreenNoMessagingApp => 'No messaging app available';

  @override
  String get selectContactScreenCouldNotOpenMessagingApp =>
      'Could not open messaging app';

  @override
  String get selectContactScreenDefaultStatus =>
      'Hey there! I am using Talkmos';

  @override
  String get selectContactScreenNoContactsFound => 'No contacts found';

  @override
  String selectContactScreenNoFriendsFoundMatching(String query) {
    return 'No friends found matching \"$query\".';
  }

  @override
  String get selectContactScreenAddFriendsToStartChatting =>
      'Add friends or search for people on Talkmos to start chatting.';

  @override
  String get selectContactScreenFindContacts => 'Find Contacts';

  @override
  String get userProfileScreenStartConversationBeforeMedia =>
      'Start a conversation before viewing shared media.';

  @override
  String get userProfileScreenStartConversationBeforeMuting =>
      'Start a conversation before muting it.';

  @override
  String get userProfileScreenStartConversationBeforeChanging =>
      'Start a conversation before changing this.';

  @override
  String userProfileScreenCouldNotOpenChat(String error) {
    return 'Could not open chat: $error';
  }

  @override
  String userProfileScreenFailedToStartCall(String error) {
    return 'Failed to start call: $error';
  }

  @override
  String get userProfileScreenMessage => 'Message';

  @override
  String get userProfileScreenAudioCall => 'Audio Call';

  @override
  String get userProfileScreenVideoCall => 'Video Call';

  @override
  String get userProfileScreenAddFriend => 'Add Friend';

  @override
  String get userProfileScreenRequested => 'Requested';

  @override
  String get userProfileScreenAcceptRequest => 'Accept';

  @override
  String get userProfileScreenRequestSent => 'Friend request sent';

  @override
  String get userProfileScreenRequestAccepted => 'Friend request accepted';

  @override
  String userProfileScreenRequestFailed(String error) {
    return 'Could not send the request: $error';
  }

  @override
  String get userProfileScreenTalkmosUsername => 'Talkmos Username';

  @override
  String get userProfileScreenUsernameCopied => 'Username copied';

  @override
  String get userProfileScreenPhone => 'Phone';

  @override
  String get userProfileScreenPhoneNumberCopied => 'Phone number copied';

  @override
  String get userProfileScreenSharedMedia => 'Shared Media';

  @override
  String get userProfileScreenMuted => 'Muted';

  @override
  String get userProfileScreenOn => 'On';

  @override
  String get userProfileScreenMediaVisibility => 'Media Visibility';

  @override
  String get userProfileScreenUnblockContact => 'Unblock Contact';

  @override
  String get userProfileScreenBlockContact => 'Block Contact';

  @override
  String get userProfileScreenDefaultBio => 'Hey there! I am using Talkmos';

  @override
  String userProfileScreenUnblockConfirmTitle(String name) {
    return 'Unblock $name?';
  }

  @override
  String userProfileScreenBlockConfirmTitle(String name) {
    return 'Block $name?';
  }

  @override
  String get userProfileScreenUnblockConfirmBody =>
      'You will be able to message and call each other again.';

  @override
  String get userProfileScreenBlockConfirmBody =>
      'They will no longer be able to message or call you, and you won\'t be able to message or call them either.';

  @override
  String userProfileScreenUnblockedToast(String name) {
    return '$name unblocked';
  }

  @override
  String userProfileScreenBlockedToast(String name) {
    return '$name blocked';
  }

  @override
  String userProfileScreenFailedToUpdateBlockStatus(String error) {
    return 'Failed to update block status: $error';
  }

  @override
  String get userProfileScreenShareContact => 'Share Contact';

  @override
  String get userProfileScreenContactCopiedToClipboard =>
      'Contact copied to clipboard';

  @override
  String get activeCallScreenAddToCall => 'Add to Call';

  @override
  String get activeCallScreenShareScreen => 'Share Screen';

  @override
  String get activeCallScreenStopSharingScreen => 'Stop Sharing';

  @override
  String get activeCallScreenNoFriendsAvailable =>
      'No friends available to invite';

  @override
  String get activeCallScreenNoContactsAvailable =>
      'No one available to invite';

  @override
  String activeCallScreenCallingName(String name) {
    return 'Calling $name…';
  }

  @override
  String activeCallScreenConnectingVideoWith(String name) {
    return 'Connecting video with $name...';
  }

  @override
  String get activeCallScreenReconnecting => 'Reconnecting…';

  @override
  String get activeCallScreenCameraOff => 'Camera off';

  @override
  String get activeCallScreenCalling => 'Calling...';

  @override
  String get activeCallScreenRinging => 'Ringing...';

  @override
  String get activeCallScreenEncryptedCall => 'Encrypted Call';

  @override
  String get activeCallScreenStartVideo => 'Start Video';

  @override
  String get activeCallScreenStopVideo => 'Stop Video';

  @override
  String get activeCallScreenMore => 'More';

  @override
  String get activeCallScreenEndCall => 'End Call';

  @override
  String get activeCallBannerTapToReturn => 'Tap to return to call';

  @override
  String get activeCallBannerOngoingCall => 'Ongoing call';

  @override
  String get friendRequestsScreenTitle => 'Friend Requests';

  @override
  String get friendRequestsScreenReceivedTab => 'Received';

  @override
  String get friendRequestsScreenSentTab => 'Sent';

  @override
  String get friendRequestsScreenSectionSent => 'Requests you\'ve sent';

  @override
  String get friendRequestsScreenSectionReceived => 'Requests you\'ve received';

  @override
  String get friendRequestsScreenNoReceived => 'No pending received requests.';

  @override
  String get friendRequestsScreenNoSent => 'No pending sent requests.';

  @override
  String get friendRequestsScreenDefaultUserName => 'User';

  @override
  String get friendRequestsScreenPrivacyHint =>
      'Only accept requests from people you know and trust.';

  @override
  String get friendRequestsScreenLearnMorePrivacy =>
      'Learn more about privacy >';

  @override
  String friendRequestsScreenAcceptError(String error) {
    return 'Could not accept request: $error';
  }

  @override
  String get friendRequestsScreenPending => 'Pending';

  @override
  String get userSearchScreenPrivateAccount =>
      'This account is private. Send a friend request to see their profile.';

  @override
  String get userSearchScreenTitle => 'Find Contacts';

  @override
  String get userSearchScreenSearchHint => 'Search by name, email or phone...';

  @override
  String get userSearchScreenBannerTitle => 'Search users by Talkmos ID';

  @override
  String get userSearchScreenBannerSubtitle =>
      'You can find people using their Talkmos ID';

  @override
  String get userSearchScreenEmptyPrompt => 'Search for people to chat with';

  @override
  String get userSearchScreenNoResults => 'No users found';

  @override
  String get userSearchScreenResultsHeader => 'Search Results';

  @override
  String get userSearchScreenDefaultUserName => 'User';

  @override
  String get userSearchScreenFriendStatus => 'Friend';

  @override
  String get userSearchScreenPendingStatus => 'Pending';

  @override
  String get userSearchScreenRequestAccepted => 'Friend request accepted!';

  @override
  String get userSearchScreenRequestSent => 'Friend request sent!';

  @override
  String userSearchScreenSendRequestError(String error) {
    return 'Could not send request: $error';
  }

  @override
  String get callsScreenAm => 'AM';

  @override
  String get callsScreenPm => 'PM';

  @override
  String get callsScreenWeekdayMon => 'Mon';

  @override
  String get callsScreenWeekdayTue => 'Tue';

  @override
  String get callsScreenWeekdayWed => 'Wed';

  @override
  String get callsScreenWeekdayThu => 'Thu';

  @override
  String get callsScreenWeekdayFri => 'Fri';

  @override
  String get callsScreenWeekdaySat => 'Sat';

  @override
  String get callsScreenWeekdaySun => 'Sun';

  @override
  String get callsScreenNoHistory => 'No call history found.';

  @override
  String get callsScreenNoMissedCalls => 'No missed calls.';

  @override
  String get callsScreenNoIncomingCalls => 'No incoming calls.';

  @override
  String get callsScreenNoOutgoingCalls => 'No outgoing calls.';

  @override
  String get callsScreenNoSearchResults => 'No calls found';

  @override
  String get callsScreenOlder => 'Older';

  @override
  String get callsScreenFilterAll => 'All';

  @override
  String get callsScreenFilterMissed => 'Missed';

  @override
  String get callsScreenFilterIncoming => 'Incoming';

  @override
  String get callsScreenFilterOutgoing => 'Outgoing';

  @override
  String get callsScreenDefaultUserName => 'User';

  @override
  String get callsScreenCannotPlaceCallMissingDetails =>
      'Cannot place call: User details missing';

  @override
  String get callsScreenCannotPlaceCallGroupNotFound =>
      'Cannot place call: Group conversation not found';

  @override
  String get callsScreenCannotPlaceCallChatNotFound =>
      'Cannot place call: Chat not found';

  @override
  String callsScreenFailedToStartCall(String error) {
    return 'Failed to start call: $error';
  }

  @override
  String get soundSelectorRowIncludedWithTalkmos => 'Included with Talkmos';

  @override
  String get soundSelectorRowPhoneDefault => 'Phone default';

  @override
  String get soundSelectorRowFollowPhoneTone => 'Follow this phone\'s own tone';

  @override
  String get soundSelectorRowChooseFromDevice => 'Choose from device';

  @override
  String get soundSelectorRowPickAnyTone => 'Pick any tone on this phone';

  @override
  String get soundSelectorRowSilentSubtitle =>
      'Show the notification without a sound';

  @override
  String get communityScreenJoinedSuccess => 'Successfully joined community!';

  @override
  String communityScreenJoinError(String error) {
    return 'Error joining: $error';
  }

  @override
  String get communityScreenDefaultName => 'Community';

  @override
  String get communityScreenSearchComingSoon => 'Community search coming soon!';

  @override
  String get communityScreenNotificationsComingSoon =>
      'Notifications coming soon.';

  @override
  String get communityScreenYourCommunities => 'Your communities';

  @override
  String get communityScreenDiscoverSection => 'Discover';

  @override
  String get communityScreenLoadError => 'Could not load communities';

  @override
  String get communityScreenNewCommunity => 'New community';

  @override
  String get communityScreenUntitled => 'Untitled';

  @override
  String get communityScreenAnnouncements => 'Announcements';

  @override
  String communityScreenMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '$count member',
    );
    return '$_temp0';
  }

  @override
  String get communityScreenNoDescription => 'No description';

  @override
  String get communityScreenPreviewPhoto => '📷 Photo';

  @override
  String get communityScreenPreviewVideo => '🎥 Video';

  @override
  String get communityScreenPreviewAudio => '🎵 Audio';

  @override
  String get communityScreenPreviewFile => '📄 File';

  @override
  String get communityScreenJoinedLabel => 'Joined';

  @override
  String get communityScreenJoinButton => 'Join';

  @override
  String get communityScreenIntroTitle => 'Introduce communities';

  @override
  String get communityScreenIntroBody =>
      'Communities bring members together in topic-based groups, and make it easy to get relevant announcements.';

  @override
  String get communityScreenStartButton => 'Start your community';

  @override
  String communityScreenImageUploadError(String error) {
    return 'Failed to upload image: $error';
  }

  @override
  String get communityScreenCreateSuccess => 'Community created successfully!';

  @override
  String get communityScreenNameLabel => 'Community name';

  @override
  String get communityScreenDescriptionLabel => 'Description';

  @override
  String get communityScreenCategoryLabel => 'Category';

  @override
  String get communityScreenCreateButton => 'Create Community';

  @override
  String communityDetailScreenLeaveError(String error) {
    return 'Failed to leave: $error';
  }

  @override
  String get communityDetailScreenLeaveTitle => 'Leave community?';

  @override
  String communityDetailScreenLeaveBody(String name) {
    return 'You\'ll stop receiving messages from $name.';
  }

  @override
  String get communityDetailScreenTitle => 'Community Info';

  @override
  String get communityDetailScreenShareInvite => 'Share invite link';

  @override
  String get communityDetailScreenLeaveButton => 'Leave Community';

  @override
  String communityDetailScreenMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '$count member',
    );
    return '$_temp0';
  }

  @override
  String get communityDetailScreenMembersHeader => 'MEMBERS';

  @override
  String communityDetailScreenMembersHeaderCount(int count) {
    return 'MEMBERS ($count)';
  }

  @override
  String communityDetailScreenMembersLoadError(String error) {
    return 'Could not load members: $error';
  }

  @override
  String get createStoryScreenCameraPhoto => 'Camera photo';

  @override
  String get createStoryScreenCameraVideo => 'Camera video';

  @override
  String get createStoryScreenTitle => 'New Status';

  @override
  String createStoryScreenTitleWithCount(int count) {
    return 'New Status ($count)';
  }

  @override
  String get createStoryScreenAddMoreTooltip => 'Add more';

  @override
  String get createStoryScreenShare => 'Share';

  @override
  String get createStoryScreenPickerTitle => 'Share a photo or video status';

  @override
  String get createStoryScreenPickerSubtitle =>
      'Pick multiple to post them all at once';

  @override
  String get createStoryScreenPhotoOption => 'Photo';

  @override
  String get createStoryScreenCaptionHint => 'Add a caption…';

  @override
  String get createStoryScreenAddStickerTooltip => 'Add Sticker';

  @override
  String get createStoryScreenFilterTooltip => 'Filter';

  @override
  String get storyViewerScreenVideoLoadError => 'Failed to load video';

  @override
  String get storyViewerScreenDeleteStory => 'Delete status';

  @override
  String get storyViewerScreenDeleteConfirm =>
      'Delete this status? People who haven\'t seen it won\'t be able to.';

  @override
  String get storyViewerScreenDeleted => 'Status deleted';

  @override
  String get storyViewerScreenDeleteFailed => 'Could not delete this status';

  @override
  String get mainNavigationNewGroup => 'New Group';

  @override
  String get mainNavigationFindContacts => 'Find Contacts';

  @override
  String get mainNavigationFriendRequests => 'Friend Requests';

  @override
  String get mainNavigationSavedMessages => 'Saved Messages';

  @override
  String get mainNavigationLightMode => 'Light Mode';

  @override
  String get mainNavigationDarkMode => 'Dark Mode';

  @override
  String get mainNavigationInviteFriends => 'Invite Friends';

  @override
  String get mainNavigationLogout => 'Log out';

  @override
  String get mainNavigationGuest => 'Guest';

  @override
  String get mainNavigationChatsTab => 'Chats';

  @override
  String get privacySettingsScreenVisibilityContacts => 'Contacts';

  @override
  String get privacySettingsScreenVisibilityNobody => 'Nobody';
}
