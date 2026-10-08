import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
    Locale('hi'),
  ];

  /// Brand name — never translate, keep identical in every locale.
  ///
  /// In en, this message translates to:
  /// **'Talkmos'**
  String get commonAppName;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get commonSend;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get commonBlock;

  /// No description provided for @commonUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get commonUnblock;

  /// No description provided for @commonMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get commonMute;

  /// No description provided for @commonUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get commonUnmute;

  /// No description provided for @commonLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get commonLeave;

  /// No description provided for @commonAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get commonAccept;

  /// No description provided for @commonDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get commonDecline;

  /// No description provided for @commonToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonToday;

  /// No description provided for @commonYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get commonYesterday;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get commonUnknown;

  /// No description provided for @commonMe.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get commonMe;

  /// No description provided for @commonYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get commonYou;

  /// No description provided for @commonSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get commonSettings;

  /// No description provided for @commonMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get commonMembers;

  /// No description provided for @commonMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get commonMember;

  /// No description provided for @commonOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get commonOpen;

  /// No description provided for @commonAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get commonAdmin;

  /// No description provided for @commonAdmins.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get commonAdmins;

  /// No description provided for @commonEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get commonEveryone;

  /// No description provided for @commonSomeone.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get commonSomeone;

  /// No description provided for @commonSilent.
  ///
  /// In en, this message translates to:
  /// **'Silent'**
  String get commonSilent;

  /// No description provided for @commonUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get commonUsername;

  /// No description provided for @commonPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get commonPassword;

  /// No description provided for @commonAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get commonAbout;

  /// No description provided for @commonPermissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get commonPermissions;

  /// No description provided for @commonMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get commonMessages;

  /// No description provided for @commonCalls.
  ///
  /// In en, this message translates to:
  /// **'Calls'**
  String get commonCalls;

  /// No description provided for @commonChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get commonChat;

  /// No description provided for @commonGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get commonGallery;

  /// No description provided for @commonLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get commonLocation;

  /// No description provided for @commonVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get commonVideo;

  /// No description provided for @commonUpdateReady.
  ///
  /// In en, this message translates to:
  /// **'An update is ready to install.'**
  String get commonUpdateReady;

  /// No description provided for @commonUpdateRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get commonUpdateRestart;

  /// No description provided for @commonAddedToCall.
  ///
  /// In en, this message translates to:
  /// **'Adding {name} to the call…'**
  String commonAddedToCall(String name);

  /// No description provided for @commonPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get commonPhoto;

  /// No description provided for @commonVoiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Voice message'**
  String get commonVoiceMessage;

  /// No description provided for @commonAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get commonAudio;

  /// No description provided for @commonDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get commonDocument;

  /// No description provided for @commonGif.
  ///
  /// In en, this message translates to:
  /// **'GIF'**
  String get commonGif;

  /// No description provided for @commonSticker.
  ///
  /// In en, this message translates to:
  /// **'Sticker'**
  String get commonSticker;

  /// No description provided for @commonFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get commonFriends;

  /// No description provided for @commonDevices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get commonDevices;

  /// No description provided for @devicesScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get devicesScreenTitle;

  /// No description provided for @devicesScreenBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your account secure'**
  String get devicesScreenBannerTitle;

  /// No description provided for @devicesScreenBannerMessage.
  ///
  /// In en, this message translates to:
  /// **'These are the devices currently signed in to your account. If you see one you don\'t recognize, log it out immediately.'**
  String get devicesScreenBannerMessage;

  /// No description provided for @devicesScreenThisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get devicesScreenThisDevice;

  /// No description provided for @devicesScreenActiveNow.
  ///
  /// In en, this message translates to:
  /// **'Active now'**
  String get devicesScreenActiveNow;

  /// No description provided for @devicesScreenLastActive.
  ///
  /// In en, this message translates to:
  /// **'Last active {date}'**
  String devicesScreenLastActive(String date);

  /// No description provided for @devicesScreenLoggedOutOn.
  ///
  /// In en, this message translates to:
  /// **'Logged out {date}'**
  String devicesScreenLoggedOutOn(String date);

  /// No description provided for @devicesScreenLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get devicesScreenLogOut;

  /// No description provided for @devicesScreenLogOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out this device?'**
  String get devicesScreenLogOutConfirmTitle;

  /// No description provided for @devicesScreenLogOutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'{deviceName} will be signed out immediately.'**
  String devicesScreenLogOutConfirmMessage(String deviceName);

  /// No description provided for @devicesScreenLogOutFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to log out device: {error}'**
  String devicesScreenLogOutFailed(String error);

  /// No description provided for @devicesScreenLoggedOut.
  ///
  /// In en, this message translates to:
  /// **'Device logged out'**
  String get devicesScreenLoggedOut;

  /// No description provided for @devicesScreenLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load devices: {error}'**
  String devicesScreenLoadFailed(String error);

  /// No description provided for @devicesScreenNoDevices.
  ///
  /// In en, this message translates to:
  /// **'No devices found'**
  String get devicesScreenNoDevices;

  /// No description provided for @commonAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get commonAccount;

  /// No description provided for @commonNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get commonNotifications;

  /// No description provided for @commonSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get commonSpeaker;

  /// No description provided for @languageSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettingsTitle;

  /// No description provided for @languageSettingsSectionHeader.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get languageSettingsSectionHeader;

  /// No description provided for @languageSettingsFollowDevice.
  ///
  /// In en, this message translates to:
  /// **'Follow device language'**
  String get languageSettingsFollowDevice;

  /// No description provided for @languageSettingsNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Translation notice'**
  String get languageSettingsNoticeTitle;

  /// No description provided for @languageSettingsNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'Some newer parts of the app may still show in English until their translations are added.'**
  String get languageSettingsNoticeBody;

  /// No description provided for @chatScreenGroupDeletedByOwner.
  ///
  /// In en, this message translates to:
  /// **'This group was deleted by its owner'**
  String get chatScreenGroupDeletedByOwner;

  /// No description provided for @chatScreenDeleteMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete message?'**
  String get chatScreenDeleteMessageTitle;

  /// No description provided for @chatScreenDeleteMessagesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} message(s)?'**
  String chatScreenDeleteMessagesConfirm(int count);

  /// No description provided for @chatScreenDeleteMessagesForMeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} message(s) for me?'**
  String chatScreenDeleteMessagesForMeConfirm(int count);

  /// No description provided for @chatScreenDeleteForMe.
  ///
  /// In en, this message translates to:
  /// **'Delete for me'**
  String get chatScreenDeleteForMe;

  /// No description provided for @chatScreenDeleteForEveryone.
  ///
  /// In en, this message translates to:
  /// **'Delete for everyone'**
  String get chatScreenDeleteForEveryone;

  /// No description provided for @chatScreenDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete: {error}'**
  String chatScreenDeleteFailed(String error);

  /// No description provided for @chatScreenCallStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to start call: {error}'**
  String chatScreenCallStartFailed(String error);

  /// No description provided for @chatScreenMicPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission denied'**
  String get chatScreenMicPermissionDenied;

  /// No description provided for @chatScreenCallWhileRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop the voice recording before starting a call'**
  String get chatScreenCallWhileRecording;

  /// No description provided for @chatScreenRecordWhileInCall.
  ///
  /// In en, this message translates to:
  /// **'You are already on a call'**
  String get chatScreenRecordWhileInCall;

  /// No description provided for @chatScreenRecordingStoppedForCall.
  ///
  /// In en, this message translates to:
  /// **'Voice recording stopped for the call'**
  String get chatScreenRecordingStoppedForCall;

  /// No description provided for @chatHeaderOnline.
  ///
  /// In en, this message translates to:
  /// **'online'**
  String get chatHeaderOnline;

  /// No description provided for @chatHeaderLastSeenToday.
  ///
  /// In en, this message translates to:
  /// **'last seen today at {time}'**
  String chatHeaderLastSeenToday(String time);

  /// No description provided for @chatHeaderLastSeenYesterday.
  ///
  /// In en, this message translates to:
  /// **'last seen yesterday at {time}'**
  String chatHeaderLastSeenYesterday(String time);

  /// No description provided for @chatHeaderLastSeenOn.
  ///
  /// In en, this message translates to:
  /// **'last seen {date} at {time}'**
  String chatHeaderLastSeenOn(String date, String time);

  /// No description provided for @chatScreenMessageTooShort.
  ///
  /// In en, this message translates to:
  /// **'Message too short'**
  String get chatScreenMessageTooShort;

  /// No description provided for @chatScreenVoiceSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send voice message: {error}'**
  String chatScreenVoiceSendFailed(String error);

  /// No description provided for @chatScreenReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get chatScreenReply;

  /// No description provided for @chatScreenForward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get chatScreenForward;

  /// No description provided for @chatScreenCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get chatScreenCopy;

  /// No description provided for @chatScreenPin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get chatScreenPin;

  /// No description provided for @chatScreenUnpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get chatScreenUnpin;

  /// No description provided for @chatScreenTranslate.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get chatScreenTranslate;

  /// No description provided for @chatScreenShowOriginal.
  ///
  /// In en, this message translates to:
  /// **'Show Original'**
  String get chatScreenShowOriginal;

  /// No description provided for @chatScreenTranslating.
  ///
  /// In en, this message translates to:
  /// **'Translating…'**
  String get chatScreenTranslating;

  /// No description provided for @chatScreenTranslated.
  ///
  /// In en, this message translates to:
  /// **'Translated'**
  String get chatScreenTranslated;

  /// No description provided for @chatScreenTranslateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t translate this message. Check your connection and try again.'**
  String get chatScreenTranslateFailed;

  /// No description provided for @chatScreenDeleteUnsend.
  ///
  /// In en, this message translates to:
  /// **'Delete / Unsend'**
  String get chatScreenDeleteUnsend;

  /// No description provided for @chatScreenCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get chatScreenCopiedToClipboard;

  /// No description provided for @chatScreenForwardedTo.
  ///
  /// In en, this message translates to:
  /// **'Forwarded to {name}'**
  String chatScreenForwardedTo(String name);

  /// No description provided for @chatScreenUploadingDocument.
  ///
  /// In en, this message translates to:
  /// **'Uploading document...'**
  String get chatScreenUploadingDocument;

  /// No description provided for @chatScreenDocumentUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Document upload failed: {error}'**
  String chatScreenDocumentUploadFailed(String error);

  /// No description provided for @chatScreenContactsPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Contacts permission is required to share a contact.'**
  String get chatScreenContactsPermissionRequired;

  /// No description provided for @chatScreenShareContactFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not share contact: {error}'**
  String chatScreenShareContactFailed(String error);

  /// No description provided for @chatScreenLocationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required to share your location.'**
  String get chatScreenLocationPermissionRequired;

  /// No description provided for @chatScreenTurnOnLocationServices.
  ///
  /// In en, this message translates to:
  /// **'Turn on location services to share your location.'**
  String get chatScreenTurnOnLocationServices;

  /// No description provided for @chatScreenGettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting your location...'**
  String get chatScreenGettingLocation;

  /// No description provided for @chatScreenShareLocationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not share location: {error}'**
  String chatScreenShareLocationFailed(String error);

  /// No description provided for @chatScreenSendingItems.
  ///
  /// In en, this message translates to:
  /// **'Sending {count} item(s)...'**
  String chatScreenSendingItems(int count);

  /// No description provided for @chatScreenMediaUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload media: {error}'**
  String chatScreenMediaUploadFailed(String error);

  /// No description provided for @chatScreenUploadingVideo.
  ///
  /// In en, this message translates to:
  /// **'Uploading video...'**
  String get chatScreenUploadingVideo;

  /// No description provided for @chatScreenVideoUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Video upload failed: {error}'**
  String chatScreenVideoUploadFailed(String error);

  /// No description provided for @chatScreenUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String chatScreenUploadFailed(String error);

  /// No description provided for @chatScreenSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String chatScreenSelectedCount(int count);

  /// No description provided for @chatScreenVideoCall.
  ///
  /// In en, this message translates to:
  /// **'Video call'**
  String get chatScreenVideoCall;

  /// No description provided for @chatScreenVoiceCall.
  ///
  /// In en, this message translates to:
  /// **'Voice call'**
  String get chatScreenVoiceCall;

  /// No description provided for @chatScreenOriginalMessageSender.
  ///
  /// In en, this message translates to:
  /// **'Original Message'**
  String get chatScreenOriginalMessageSender;

  /// No description provided for @chatScreenOriginalMessageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Original message not found in history'**
  String get chatScreenOriginalMessageNotFound;

  /// No description provided for @homeScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get homeScreenTitle;

  /// No description provided for @homeScreenArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get homeScreenArchived;

  /// No description provided for @homeScreenMyStory.
  ///
  /// In en, this message translates to:
  /// **'My Story'**
  String get homeScreenMyStory;

  /// No description provided for @homeScreenFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get homeScreenFilterAll;

  /// No description provided for @homeScreenFilterUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get homeScreenFilterUnread;

  /// No description provided for @homeScreenFilterGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get homeScreenFilterGroups;

  /// No description provided for @homeScreenFilterChannels.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get homeScreenFilterChannels;

  /// No description provided for @homeScreenFilterBots.
  ///
  /// In en, this message translates to:
  /// **'Bots'**
  String get homeScreenFilterBots;

  /// No description provided for @homeScreenPinChat.
  ///
  /// In en, this message translates to:
  /// **'Pin Chat'**
  String get homeScreenPinChat;

  /// No description provided for @homeScreenUnpinChat.
  ///
  /// In en, this message translates to:
  /// **'Unpin Chat'**
  String get homeScreenUnpinChat;

  /// No description provided for @homeScreenMuteNotifications.
  ///
  /// In en, this message translates to:
  /// **'Mute Notifications'**
  String get homeScreenMuteNotifications;

  /// No description provided for @homeScreenArchiveChat.
  ///
  /// In en, this message translates to:
  /// **'Archive Chat'**
  String get homeScreenArchiveChat;

  /// No description provided for @homeScreenUnarchiveChat.
  ///
  /// In en, this message translates to:
  /// **'Unarchive Chat'**
  String get homeScreenUnarchiveChat;

  /// No description provided for @homeScreenLeaveGroup.
  ///
  /// In en, this message translates to:
  /// **'Leave Group'**
  String get homeScreenLeaveGroup;

  /// No description provided for @homeScreenBlockContact.
  ///
  /// In en, this message translates to:
  /// **'Block Contact'**
  String get homeScreenBlockContact;

  /// No description provided for @homeScreenUnblockContact.
  ///
  /// In en, this message translates to:
  /// **'Unblock Contact'**
  String get homeScreenUnblockContact;

  /// No description provided for @homeScreenDeleteChat.
  ///
  /// In en, this message translates to:
  /// **'Delete Chat'**
  String get homeScreenDeleteChat;

  /// No description provided for @homeScreenContactNotIdentified.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t identify this contact'**
  String get homeScreenContactNotIdentified;

  /// No description provided for @homeScreenBlockConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Block {name}?'**
  String homeScreenBlockConfirmTitle(String name);

  /// No description provided for @homeScreenBlockConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'They will no longer be able to message or call you, and you won\'t be able to message or call them either.'**
  String get homeScreenBlockConfirmBody;

  /// No description provided for @homeScreenContactBlocked.
  ///
  /// In en, this message translates to:
  /// **'{name} blocked'**
  String homeScreenContactBlocked(String name);

  /// No description provided for @homeScreenContactUnblocked.
  ///
  /// In en, this message translates to:
  /// **'{name} unblocked'**
  String homeScreenContactUnblocked(String name);

  /// No description provided for @homeScreenBlockStatusUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update block status: {error}'**
  String homeScreenBlockStatusUpdateFailed(String error);

  /// No description provided for @homeScreenDeleteChatBody.
  ///
  /// In en, this message translates to:
  /// **'Delete your chat with {name}? It will reappear if a new message arrives.'**
  String homeScreenDeleteChatBody(String name);

  /// No description provided for @homeScreenLeaveGroupBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave \"{name}\"?'**
  String homeScreenLeaveGroupBody(String name);

  /// No description provided for @homeScreenLeaveGroupFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to leave group'**
  String get homeScreenLeaveGroupFailed;

  /// No description provided for @homeScreenNoChatsFound.
  ///
  /// In en, this message translates to:
  /// **'No chats found'**
  String get homeScreenNoChatsFound;

  /// No description provided for @homeScreenNoChatsYet.
  ///
  /// In en, this message translates to:
  /// **'No chats yet'**
  String get homeScreenNoChatsYet;

  /// No description provided for @homeScreenNoConversationsMatch.
  ///
  /// In en, this message translates to:
  /// **'No conversations match “{query}”.'**
  String homeScreenNoConversationsMatch(String query);

  /// No description provided for @homeScreenEmptyStateHint.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation or create a group\nto see it here.'**
  String get homeScreenEmptyStateHint;

  /// No description provided for @homeScreenSearchPeople.
  ///
  /// In en, this message translates to:
  /// **'Search people'**
  String get homeScreenSearchPeople;

  /// No description provided for @createGroupScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createGroupScreenTitle;

  /// No description provided for @createGroupScreenNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get createGroupScreenNext;

  /// No description provided for @createGroupScreenNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get createGroupScreenNameLabel;

  /// No description provided for @createGroupScreenNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter group name'**
  String get createGroupScreenNameHint;

  /// No description provided for @createGroupScreenDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Group Description'**
  String get createGroupScreenDescriptionLabel;

  /// No description provided for @createGroupScreenOptional.
  ///
  /// In en, this message translates to:
  /// **'(Optional)'**
  String get createGroupScreenOptional;

  /// No description provided for @createGroupScreenDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Tell people what this group is about...'**
  String get createGroupScreenDescriptionHint;

  /// No description provided for @createGroupScreenDescriptionHelper.
  ///
  /// In en, this message translates to:
  /// **'You can add a description later'**
  String get createGroupScreenDescriptionHelper;

  /// No description provided for @createGroupScreenUploadingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get createGroupScreenUploadingPhoto;

  /// No description provided for @createGroupScreenAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add group photo'**
  String get createGroupScreenAddPhoto;

  /// No description provided for @createGroupScreenChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change group photo'**
  String get createGroupScreenChangePhoto;

  /// No description provided for @createGroupScreenPhotoUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload photo: {error}'**
  String createGroupScreenPhotoUploadFailed(String error);

  /// No description provided for @createGroupScreenEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a group name'**
  String get createGroupScreenEnterName;

  /// No description provided for @createGroupScreenSelectAtLeastOneMember.
  ///
  /// In en, this message translates to:
  /// **'Select at least 1 member'**
  String get createGroupScreenSelectAtLeastOneMember;

  /// No description provided for @createGroupScreenCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create group: {error}'**
  String createGroupScreenCreateFailed(String error);

  /// No description provided for @createGroupScreenSelectMembers.
  ///
  /// In en, this message translates to:
  /// **'Select Members'**
  String get createGroupScreenSelectMembers;

  /// No description provided for @createGroupScreenSelectMembersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add people you want to add in this group'**
  String get createGroupScreenSelectMembersSubtitle;

  /// No description provided for @createGroupScreenSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Selected'**
  String createGroupScreenSelectedCount(int count);

  /// No description provided for @createGroupScreenSearchMembersHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, username or Talkmos ID'**
  String get createGroupScreenSearchMembersHint;

  /// No description provided for @createGroupScreenNoContactsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet. Add friends to start a group.'**
  String get createGroupScreenNoContactsEmpty;

  /// No description provided for @createGroupScreenNoContactsMatch.
  ///
  /// In en, this message translates to:
  /// **'No contacts match \"{query}\".'**
  String createGroupScreenNoContactsMatch(String query);

  /// No description provided for @createGroupScreenMemberCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} Member} other{{count} Members}}'**
  String createGroupScreenMemberCount(int count);

  /// No description provided for @archivedChatsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archivedChatsScreenTitle;

  /// No description provided for @archivedChatsScreenUnarchiveChat.
  ///
  /// In en, this message translates to:
  /// **'Unarchive Chat'**
  String get archivedChatsScreenUnarchiveChat;

  /// No description provided for @archivedChatsScreenMuteNotifications.
  ///
  /// In en, this message translates to:
  /// **'Mute Notifications'**
  String get archivedChatsScreenMuteNotifications;

  /// No description provided for @archivedChatsScreenLeaveGroup.
  ///
  /// In en, this message translates to:
  /// **'Leave Group'**
  String get archivedChatsScreenLeaveGroup;

  /// No description provided for @archivedChatsScreenDeleteChat.
  ///
  /// In en, this message translates to:
  /// **'Delete Chat'**
  String get archivedChatsScreenDeleteChat;

  /// No description provided for @archivedChatsScreenDeleteChatBody.
  ///
  /// In en, this message translates to:
  /// **'Delete your chat with {name}? It will reappear if a new message arrives.'**
  String archivedChatsScreenDeleteChatBody(String name);

  /// No description provided for @archivedChatsScreenLeaveGroupBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave \"{name}\"?'**
  String archivedChatsScreenLeaveGroupBody(String name);

  /// No description provided for @archivedChatsScreenLeaveGroupFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to leave group'**
  String get archivedChatsScreenLeaveGroupFailed;

  /// No description provided for @archivedChatsScreenEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No archived chats'**
  String get archivedChatsScreenEmptyTitle;

  /// No description provided for @archivedChatsScreenEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Chats you archive will show up here and stay out of your main list.'**
  String get archivedChatsScreenEmptyBody;

  /// No description provided for @groupProfileScreenFailedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load group details'**
  String get groupProfileScreenFailedToLoad;

  /// No description provided for @groupProfileScreenImageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Group image updated successfully!'**
  String get groupProfileScreenImageUpdated;

  /// No description provided for @groupProfileScreenUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload group photo: {error}'**
  String groupProfileScreenUploadFailed(String error);

  /// No description provided for @groupProfileScreenDescriptionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Group description updated'**
  String get groupProfileScreenDescriptionUpdated;

  /// No description provided for @groupProfileScreenDescriptionUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update description'**
  String get groupProfileScreenDescriptionUpdateFailed;

  /// No description provided for @groupProfileScreenNameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Group name updated'**
  String get groupProfileScreenNameUpdated;

  /// No description provided for @groupProfileScreenNameUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update name'**
  String get groupProfileScreenNameUpdateFailed;

  /// No description provided for @groupProfileScreenLeaveGroup.
  ///
  /// In en, this message translates to:
  /// **'Leave Group'**
  String get groupProfileScreenLeaveGroup;

  /// No description provided for @groupProfileScreenLeaveGroupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave this group?'**
  String get groupProfileScreenLeaveGroupConfirm;

  /// No description provided for @groupProfileScreenLeaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to leave group'**
  String get groupProfileScreenLeaveFailed;

  /// No description provided for @groupProfileScreenDeleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete Group'**
  String get groupProfileScreenDeleteGroup;

  /// No description provided for @groupProfileScreenDeleteGroupConfirm.
  ///
  /// In en, this message translates to:
  /// **'This deletes the group for everyone, including its messages. This cannot be undone.'**
  String get groupProfileScreenDeleteGroupConfirm;

  /// No description provided for @groupProfileScreenDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete group'**
  String get groupProfileScreenDeleteFailed;

  /// No description provided for @groupProfileScreenGroupDeleted.
  ///
  /// In en, this message translates to:
  /// **'Group deleted'**
  String get groupProfileScreenGroupDeleted;

  /// No description provided for @groupProfileScreenRemoveMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Member'**
  String get groupProfileScreenRemoveMemberTitle;

  /// No description provided for @groupProfileScreenRemoveMemberBody.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from the group?'**
  String groupProfileScreenRemoveMemberBody(String name);

  /// No description provided for @groupProfileScreenMemberRemoved.
  ///
  /// In en, this message translates to:
  /// **'{name} removed'**
  String groupProfileScreenMemberRemoved(String name);

  /// No description provided for @groupProfileScreenRemoveMemberFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove member'**
  String get groupProfileScreenRemoveMemberFailed;

  /// No description provided for @groupProfileScreenAddMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Members'**
  String get groupProfileScreenAddMembersTitle;

  /// No description provided for @groupProfileScreenAddButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Add ({count})'**
  String groupProfileScreenAddButtonLabel(int count);

  /// No description provided for @groupProfileScreenMembersAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Added {count} member} other{Added {count} members}}'**
  String groupProfileScreenMembersAdded(int count);

  /// No description provided for @groupProfileScreenAddMembersFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add members: {error}'**
  String groupProfileScreenAddMembersFailed(String error);

  /// No description provided for @groupProfileScreenNoMoreContacts.
  ///
  /// In en, this message translates to:
  /// **'No more contacts to add'**
  String get groupProfileScreenNoMoreContacts;

  /// No description provided for @groupProfileScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Group Settings'**
  String get groupProfileScreenTitle;

  /// No description provided for @groupProfileScreenInviteMembers.
  ///
  /// In en, this message translates to:
  /// **'Invite Members'**
  String get groupProfileScreenInviteMembers;

  /// No description provided for @groupProfileScreenPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get groupProfileScreenPrivacy;

  /// No description provided for @groupProfileScreenEditGroupInfo.
  ///
  /// In en, this message translates to:
  /// **'Edit Group Info'**
  String get groupProfileScreenEditGroupInfo;

  /// No description provided for @groupProfileScreenMediaVisibility.
  ///
  /// In en, this message translates to:
  /// **'Media Visibility'**
  String get groupProfileScreenMediaVisibility;

  /// No description provided for @groupProfileScreenMuteNotifications.
  ///
  /// In en, this message translates to:
  /// **'Mute Notifications'**
  String get groupProfileScreenMuteNotifications;

  /// No description provided for @groupProfileScreenDangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get groupProfileScreenDangerZone;

  /// No description provided for @groupProfileScreenMemberCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} Member} other{{count} Members}}'**
  String groupProfileScreenMemberCount(int count);

  /// No description provided for @groupProfileScreenMembersCountTitle.
  ///
  /// In en, this message translates to:
  /// **'Members ({count})'**
  String groupProfileScreenMembersCountTitle(int count);

  /// No description provided for @groupProfileScreenNoAdminsYet.
  ///
  /// In en, this message translates to:
  /// **'No admins yet.'**
  String get groupProfileScreenNoAdminsYet;

  /// No description provided for @groupProfileScreenNoMembersYet.
  ///
  /// In en, this message translates to:
  /// **'No members yet.'**
  String get groupProfileScreenNoMembersYet;

  /// No description provided for @groupProfileScreenOwnerRole.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get groupProfileScreenOwnerRole;

  /// No description provided for @groupProfileScreenGroupNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupProfileScreenGroupNameLabel;

  /// No description provided for @groupProfileScreenDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get groupProfileScreenDescriptionLabel;

  /// No description provided for @mediaPreviewScreenAddTextLabelTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Text Label'**
  String get mediaPreviewScreenAddTextLabelTitle;

  /// No description provided for @mediaPreviewScreenTypeTextHint.
  ///
  /// In en, this message translates to:
  /// **'Type text here...'**
  String get mediaPreviewScreenTypeTextHint;

  /// No description provided for @mediaPreviewScreenFileSize.
  ///
  /// In en, this message translates to:
  /// **'{size}'**
  String mediaPreviewScreenFileSize(String size);

  /// No description provided for @mediaPreviewScreenCropImageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Crop Image'**
  String get mediaPreviewScreenCropImageTooltip;

  /// No description provided for @mediaPreviewScreenRotateImageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Rotate Image'**
  String get mediaPreviewScreenRotateImageTooltip;

  /// No description provided for @mediaPreviewScreenAddTextTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add Text'**
  String get mediaPreviewScreenAddTextTooltip;

  /// No description provided for @mediaPreviewScreenDrawDoodleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Draw Doodle'**
  String get mediaPreviewScreenDrawDoodleTooltip;

  /// No description provided for @mediaPreviewScreenUndoStrokeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Undo last stroke'**
  String get mediaPreviewScreenUndoStrokeTooltip;

  /// No description provided for @mediaPreviewScreenCaptionHint.
  ///
  /// In en, this message translates to:
  /// **'Add a caption…'**
  String get mediaPreviewScreenCaptionHint;

  /// No description provided for @groupPermissionsScreenSendMessagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Send Messages'**
  String get groupPermissionsScreenSendMessagesLabel;

  /// No description provided for @groupPermissionsScreenSendMessagesDescription.
  ///
  /// In en, this message translates to:
  /// **'Who can post in this group'**
  String get groupPermissionsScreenSendMessagesDescription;

  /// No description provided for @groupPermissionsScreenEditInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit Group Info'**
  String get groupPermissionsScreenEditInfoLabel;

  /// No description provided for @groupPermissionsScreenEditInfoDescription.
  ///
  /// In en, this message translates to:
  /// **'Who can change the name, photo and description'**
  String get groupPermissionsScreenEditInfoDescription;

  /// No description provided for @groupPermissionsScreenAddMembersLabel.
  ///
  /// In en, this message translates to:
  /// **'Add Members'**
  String get groupPermissionsScreenAddMembersLabel;

  /// No description provided for @groupPermissionsScreenAddMembersDescription.
  ///
  /// In en, this message translates to:
  /// **'Who can invite people into this group'**
  String get groupPermissionsScreenAddMembersDescription;

  /// No description provided for @groupPermissionsScreenAdminOnlyNotice.
  ///
  /// In en, this message translates to:
  /// **'Only group admins can change these settings.'**
  String get groupPermissionsScreenAdminOnlyNotice;

  /// No description provided for @groupPermissionsScreenAllMembers.
  ///
  /// In en, this message translates to:
  /// **'All members'**
  String get groupPermissionsScreenAllMembers;

  /// No description provided for @groupPermissionsScreenOnlyAdmins.
  ///
  /// In en, this message translates to:
  /// **'Only admins'**
  String get groupPermissionsScreenOnlyAdmins;

  /// No description provided for @groupPermissionsScreenUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update: {error}'**
  String groupPermissionsScreenUpdateFailed(String error);

  /// No description provided for @videoPlayerScreenLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load video'**
  String get videoPlayerScreenLoadFailed;

  /// No description provided for @sharedMediaScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Shared Media'**
  String get sharedMediaScreenTitle;

  /// No description provided for @sharedMediaScreenLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load shared media'**
  String get sharedMediaScreenLoadFailed;

  /// No description provided for @sharedMediaScreenEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No media shared yet'**
  String get sharedMediaScreenEmptyTitle;

  /// No description provided for @sharedMediaScreenEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Photos and videos you send or receive\nhere will show up in this gallery.'**
  String get sharedMediaScreenEmptyBody;

  /// No description provided for @imageViewerLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get imageViewerLoadFailed;

  /// No description provided for @chatBubbleEdited.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get chatBubbleEdited;

  /// No description provided for @chatBubbleReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get chatBubbleReadMore;

  /// No description provided for @chatBubbleReadLess.
  ///
  /// In en, this message translates to:
  /// **'Read less'**
  String get chatBubbleReadLess;

  /// No description provided for @chatInputBarEditMessage.
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get chatInputBarEditMessage;

  /// No description provided for @chatInputBarHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message…'**
  String get chatInputBarHint;

  /// No description provided for @chatHeaderTypingLabel.
  ///
  /// In en, this message translates to:
  /// **'typing'**
  String get chatHeaderTypingLabel;

  /// No description provided for @contextActionMenuActionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get contextActionMenuActionsLabel;

  /// No description provided for @chatBodyPrivacyBanner.
  ///
  /// In en, this message translates to:
  /// **'Messages are private to this chat.'**
  String get chatBodyPrivacyBanner;

  /// No description provided for @chatBodyYouBlocked.
  ///
  /// In en, this message translates to:
  /// **'You blocked {peerName}'**
  String chatBodyYouBlocked(String peerName);

  /// No description provided for @chatBodyNoMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get chatBodyNoMessagesYet;

  /// No description provided for @chatBodySayHi.
  ///
  /// In en, this message translates to:
  /// **'Say hi to {name} to start the conversation.'**
  String chatBodySayHi(String name);

  /// No description provided for @recentChatTileContactWithName.
  ///
  /// In en, this message translates to:
  /// **'Contact: {name}'**
  String recentChatTileContactWithName(String name);

  /// No description provided for @recentChatTileContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get recentChatTileContact;

  /// No description provided for @recentChatTileTapToOpen.
  ///
  /// In en, this message translates to:
  /// **'Tap to open conversation'**
  String get recentChatTileTapToOpen;

  /// No description provided for @mediaVisibilityPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Talkmos needs permission to add to your gallery. You can grant it in system settings.'**
  String get mediaVisibilityPermissionNeeded;

  /// No description provided for @mediaVisibilitySheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Media visibility'**
  String get mediaVisibilitySheetTitle;

  /// No description provided for @mediaVisibilitySheetDescription.
  ///
  /// In en, this message translates to:
  /// **'Whether photos and videos from this chat are saved to this device\'s gallery.'**
  String get mediaVisibilitySheetDescription;

  /// No description provided for @mediaVisibilitySheetFollowsGlobal.
  ///
  /// In en, this message translates to:
  /// **'Follows the global Save to Photos setting'**
  String get mediaVisibilitySheetFollowsGlobal;

  /// No description provided for @wallpaperPickerNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get wallpaperPickerNone;

  /// No description provided for @attachmentSheetDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get attachmentSheetDocument;

  /// No description provided for @attachmentSheetCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get attachmentSheetCamera;

  /// No description provided for @attachmentSheetContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get attachmentSheetContact;

  /// No description provided for @forwardMessageSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Forward to'**
  String get forwardMessageSheetTitle;

  /// No description provided for @forwardMessageSheetNoChats.
  ///
  /// In en, this message translates to:
  /// **'No chats available'**
  String get forwardMessageSheetNoChats;

  /// No description provided for @pinnedMessageBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Pinned Message'**
  String get pinnedMessageBannerTitle;

  /// No description provided for @pinnedMessageBannerConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Unpin message?'**
  String get pinnedMessageBannerConfirmTitle;

  /// No description provided for @pinnedMessageBannerConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unpin this message?'**
  String get pinnedMessageBannerConfirmBody;

  /// No description provided for @pinnedMessageBannerUnpinAction.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get pinnedMessageBannerUnpinAction;

  /// No description provided for @wizardStepHeaderStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String wizardStepHeaderStepOf(int current, int total);

  /// No description provided for @deletedMessageBody.
  ///
  /// In en, this message translates to:
  /// **'This message was deleted'**
  String get deletedMessageBody;

  /// No description provided for @voiceMessageFailedToPlay.
  ///
  /// In en, this message translates to:
  /// **'Failed to play audio'**
  String get voiceMessageFailedToPlay;

  /// No description provided for @imageMessageFailedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get imageMessageFailedToLoad;

  /// No description provided for @locationMessageCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get locationMessageCurrentLocation;

  /// No description provided for @documentMessageDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get documentMessageDefaultName;

  /// No description provided for @documentMessageFileExtensionFallback.
  ///
  /// In en, this message translates to:
  /// **'FILE'**
  String get documentMessageFileExtensionFallback;

  /// No description provided for @documentMessageOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open file: {reason}'**
  String documentMessageOpenFailed(String reason);

  /// No description provided for @documentMessageDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not download file'**
  String get documentMessageDownloadFailed;

  /// No description provided for @documentMessagePageCountOne.
  ///
  /// In en, this message translates to:
  /// **'1 page'**
  String get documentMessagePageCountOne;

  /// No description provided for @documentMessagePageCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pages'**
  String documentMessagePageCount(int count);

  /// No description provided for @completeProfileScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get completeProfileScreenTitle;

  /// No description provided for @completeProfileScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us who you are so friends can find you.'**
  String get completeProfileScreenSubtitle;

  /// No description provided for @completeProfileScreenFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get completeProfileScreenFullName;

  /// No description provided for @completeProfileScreenFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Alex Morgan'**
  String get completeProfileScreenFullNameHint;

  /// No description provided for @completeProfileScreenNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get completeProfileScreenNameRequired;

  /// No description provided for @completeProfileScreenUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. alexmorgan'**
  String get completeProfileScreenUsernameHint;

  /// No description provided for @completeProfileScreenUsernameMinLength.
  ///
  /// In en, this message translates to:
  /// **'At least 3 characters'**
  String get completeProfileScreenUsernameMinLength;

  /// No description provided for @completeProfileScreenFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get completeProfileScreenFinish;

  /// No description provided for @phoneLoginScreenSelectCountryCode.
  ///
  /// In en, this message translates to:
  /// **'Select Country Code'**
  String get phoneLoginScreenSelectCountryCode;

  /// No description provided for @phoneLoginScreenInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 10-digit phone number'**
  String get phoneLoginScreenInvalidPhone;

  /// No description provided for @phoneLoginScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Login or register to start chatting'**
  String get phoneLoginScreenSubtitle;

  /// No description provided for @phoneLoginScreenPhoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneLoginScreenPhoneNumberLabel;

  /// No description provided for @phoneLoginScreenContinueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get phoneLoginScreenContinueWithApple;

  /// No description provided for @phoneLoginScreenAppleComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in coming soon'**
  String get phoneLoginScreenAppleComingSoon;

  /// No description provided for @phoneLoginScreenContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get phoneLoginScreenContinueWithGoogle;

  /// No description provided for @phoneLoginScreenPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get phoneLoginScreenPhoneHint;

  /// No description provided for @phoneLoginScreenContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get phoneLoginScreenContinue;

  /// No description provided for @phoneLoginScreenVerificationNote.
  ///
  /// In en, this message translates to:
  /// **'We will send you a verification code\nto confirm your number'**
  String get phoneLoginScreenVerificationNote;

  /// No description provided for @phoneLoginScreenOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get phoneLoginScreenOr;

  /// No description provided for @phoneLoginScreenAgreeTerms.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our'**
  String get phoneLoginScreenAgreeTerms;

  /// No description provided for @phoneLoginScreenTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get phoneLoginScreenTermsOfService;

  /// No description provided for @phoneLoginScreenAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get phoneLoginScreenAnd;

  /// No description provided for @phoneLoginScreenPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get phoneLoginScreenPrivacyPolicy;

  /// No description provided for @phoneConfirmationScreenSelectCountryCode.
  ///
  /// In en, this message translates to:
  /// **'Select Country Code'**
  String get phoneConfirmationScreenSelectCountryCode;

  /// No description provided for @phoneConfirmationScreenInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 10-digit phone number'**
  String get phoneConfirmationScreenInvalidPhone;

  /// No description provided for @phoneConfirmationScreenPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get phoneConfirmationScreenPhoneHint;

  /// No description provided for @phoneConfirmationScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Your Phone Number'**
  String get phoneConfirmationScreenTitle;

  /// No description provided for @phoneConfirmationScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'To keep your account secure and connect with your contacts, please enter your mobile number.'**
  String get phoneConfirmationScreenSubtitle;

  /// No description provided for @phoneConfirmationScreenConfirmContinue.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Continue'**
  String get phoneConfirmationScreenConfirmContinue;

  /// No description provided for @otpVerificationScreenEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code'**
  String get otpVerificationScreenEnterCode;

  /// No description provided for @otpVerificationScreenCodeResent.
  ///
  /// In en, this message translates to:
  /// **'Code resent successfully'**
  String get otpVerificationScreenCodeResent;

  /// No description provided for @otpVerificationScreenReceivedOtp.
  ///
  /// In en, this message translates to:
  /// **'Received OTP from Backend'**
  String get otpVerificationScreenReceivedOtp;

  /// No description provided for @otpVerificationScreenOtpFilled.
  ///
  /// In en, this message translates to:
  /// **'OTP filled into text field'**
  String get otpVerificationScreenOtpFilled;

  /// No description provided for @otpVerificationScreenDirectOtpNote.
  ///
  /// In en, this message translates to:
  /// **'Direct OTP from server • Tap code to re-fill'**
  String get otpVerificationScreenDirectOtpNote;

  /// No description provided for @otpVerificationScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your number'**
  String get otpVerificationScreenTitle;

  /// No description provided for @otpVerificationScreenSentTo.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to {phone}'**
  String otpVerificationScreenSentTo(String phone);

  /// No description provided for @otpVerificationScreenVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get otpVerificationScreenVerify;

  /// No description provided for @otpVerificationScreenDidntGetCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t get the code? '**
  String get otpVerificationScreenDidntGetCode;

  /// No description provided for @otpVerificationScreenSending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get otpVerificationScreenSending;

  /// No description provided for @otpVerificationScreenResend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get otpVerificationScreenResend;

  /// No description provided for @registerScreenAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully!'**
  String get registerScreenAccountCreated;

  /// No description provided for @registerScreenCreateYourPrefix.
  ///
  /// In en, this message translates to:
  /// **'Create your '**
  String get registerScreenCreateYourPrefix;

  /// No description provided for @registerScreenAccountWord.
  ///
  /// In en, this message translates to:
  /// **'account'**
  String get registerScreenAccountWord;

  /// No description provided for @registerScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join Talkmos and start connecting with your team and community.'**
  String get registerScreenSubtitle;

  /// No description provided for @registerScreenFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get registerScreenFullName;

  /// No description provided for @registerScreenFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get registerScreenFullNameHint;

  /// No description provided for @registerScreenNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get registerScreenNameRequired;

  /// No description provided for @registerScreenEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get registerScreenEmailAddress;

  /// No description provided for @registerScreenEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get registerScreenEmailHint;

  /// No description provided for @registerScreenEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get registerScreenEmailRequired;

  /// No description provided for @registerScreenEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get registerScreenEmailInvalid;

  /// No description provided for @registerScreenPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get registerScreenPasswordHint;

  /// No description provided for @registerScreenPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get registerScreenPasswordRequired;

  /// No description provided for @registerScreenPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get registerScreenPasswordMinLength;

  /// No description provided for @registerScreenConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get registerScreenConfirmPassword;

  /// No description provided for @registerScreenConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get registerScreenConfirmPasswordHint;

  /// No description provided for @registerScreenConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm password is required'**
  String get registerScreenConfirmPasswordRequired;

  /// No description provided for @registerScreenPasswordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get registerScreenPasswordsMismatch;

  /// No description provided for @registerScreenSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get registerScreenSignUp;

  /// No description provided for @registerScreenOrContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get registerScreenOrContinueWith;

  /// No description provided for @registerScreenSignInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign In with Google'**
  String get registerScreenSignInWithGoogle;

  /// No description provided for @registerScreenAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get registerScreenAlreadyHaveAccount;

  /// No description provided for @registerScreenSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get registerScreenSignIn;

  /// No description provided for @loginScreenWelcomeBackTo.
  ///
  /// In en, this message translates to:
  /// **'Welcome back to '**
  String get loginScreenWelcomeBackTo;

  /// No description provided for @loginScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to connect with your team and access your community.'**
  String get loginScreenSubtitle;

  /// No description provided for @loginScreenPhoneOrUsername.
  ///
  /// In en, this message translates to:
  /// **'Phone or Username'**
  String get loginScreenPhoneOrUsername;

  /// No description provided for @loginScreenPhoneOrUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'+1234567890 or username'**
  String get loginScreenPhoneOrUsernameHint;

  /// No description provided for @loginScreenPhoneOrUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone or username is required'**
  String get loginScreenPhoneOrUsernameRequired;

  /// No description provided for @loginScreenPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get loginScreenPasswordHint;

  /// No description provided for @loginScreenPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get loginScreenPasswordRequired;

  /// No description provided for @loginScreenForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginScreenForgotPassword;

  /// No description provided for @loginScreenSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginScreenSignIn;

  /// No description provided for @loginScreenOrContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get loginScreenOrContinueWith;

  /// No description provided for @loginScreenSignInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign In with Google'**
  String get loginScreenSignInWithGoogle;

  /// No description provided for @loginScreenSignInWithPhoneOtp.
  ///
  /// In en, this message translates to:
  /// **'Sign In with Phone OTP'**
  String get loginScreenSignInWithPhoneOtp;

  /// No description provided for @loginScreenDontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get loginScreenDontHaveAccount;

  /// No description provided for @loginScreenSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get loginScreenSignUp;

  /// No description provided for @welcomeScreenTagline.
  ///
  /// In en, this message translates to:
  /// **'Chat. Meet. Collaborate.'**
  String get welcomeScreenTagline;

  /// No description provided for @welcomeScreenDescription.
  ///
  /// In en, this message translates to:
  /// **'All-in-one communication platform for chats, calls, smart meetings & communities.'**
  String get welcomeScreenDescription;

  /// No description provided for @welcomeScreenLetsStart.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Start'**
  String get welcomeScreenLetsStart;

  /// No description provided for @forgotPasswordScreenEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email or phone number.'**
  String get forgotPasswordScreenEmailRequired;

  /// No description provided for @forgotPasswordScreenCodeResent.
  ///
  /// In en, this message translates to:
  /// **'A new code has been sent.'**
  String get forgotPasswordScreenCodeResent;

  /// No description provided for @forgotPasswordScreenIncompleteCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter the full 6-digit code.'**
  String get forgotPasswordScreenIncompleteCode;

  /// No description provided for @forgotPasswordScreenPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get forgotPasswordScreenPasswordMinLength;

  /// No description provided for @forgotPasswordScreenPasswordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get forgotPasswordScreenPasswordsMismatch;

  /// No description provided for @forgotPasswordScreenTitleEmail.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordScreenTitleEmail;

  /// No description provided for @forgotPasswordScreenTitleOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get forgotPasswordScreenTitleOtp;

  /// No description provided for @forgotPasswordScreenTitleNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set New Password'**
  String get forgotPasswordScreenTitleNewPassword;

  /// No description provided for @forgotPasswordScreenSubtitleEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email or phone and we\'ll send you a verification code.'**
  String get forgotPasswordScreenSubtitleEmail;

  /// No description provided for @forgotPasswordScreenSubtitleOtp.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox or messages for the 6-digit code we sent.'**
  String get forgotPasswordScreenSubtitleOtp;

  /// No description provided for @forgotPasswordScreenSubtitleNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a strong password you haven\'t used before.'**
  String get forgotPasswordScreenSubtitleNewPassword;

  /// No description provided for @forgotPasswordScreenEmailOrPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Email or Phone Number'**
  String get forgotPasswordScreenEmailOrPhoneLabel;

  /// No description provided for @forgotPasswordScreenEmailOrPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'name@example.com or +91...'**
  String get forgotPasswordScreenEmailOrPhoneHint;

  /// No description provided for @forgotPasswordScreenSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get forgotPasswordScreenSendCode;

  /// No description provided for @forgotPasswordScreenCodeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Code sent to {email}'**
  String forgotPasswordScreenCodeSentTo(String email);

  /// No description provided for @forgotPasswordScreenVerifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get forgotPasswordScreenVerifyCode;

  /// No description provided for @forgotPasswordScreenDidntReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive a code? '**
  String get forgotPasswordScreenDidntReceiveCode;

  /// No description provided for @forgotPasswordScreenResend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get forgotPasswordScreenResend;

  /// No description provided for @forgotPasswordScreenNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get forgotPasswordScreenNewPasswordLabel;

  /// No description provided for @forgotPasswordScreenAtLeast8Chars.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get forgotPasswordScreenAtLeast8Chars;

  /// No description provided for @forgotPasswordScreenConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get forgotPasswordScreenConfirmPasswordLabel;

  /// No description provided for @forgotPasswordScreenReenterPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get forgotPasswordScreenReenterPassword;

  /// No description provided for @forgotPasswordScreenResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get forgotPasswordScreenResetPassword;

  /// No description provided for @forgotPasswordScreenChars8Plus.
  ///
  /// In en, this message translates to:
  /// **'8+ chars'**
  String get forgotPasswordScreenChars8Plus;

  /// No description provided for @forgotPasswordScreenUppercase.
  ///
  /// In en, this message translates to:
  /// **'Uppercase'**
  String get forgotPasswordScreenUppercase;

  /// No description provided for @forgotPasswordScreenNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get forgotPasswordScreenNumber;

  /// No description provided for @forgotPasswordScreenSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Password Reset!'**
  String get forgotPasswordScreenSuccessTitle;

  /// No description provided for @forgotPasswordScreenSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Your password has been successfully updated.\nYou can now log in with your new password.'**
  String get forgotPasswordScreenSuccessMessage;

  /// No description provided for @forgotPasswordScreenBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get forgotPasswordScreenBackToLogin;

  /// No description provided for @editProfileScreenUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get editProfileScreenUpdateSuccess;

  /// No description provided for @editProfileScreenUploadPhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload photo: {error}'**
  String editProfileScreenUploadPhotoFailed(String error);

  /// No description provided for @editProfileScreenChangePhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Profile Photo'**
  String get editProfileScreenChangePhotoTitle;

  /// No description provided for @editProfileScreenChoosePhotoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a photo to represent you'**
  String get editProfileScreenChoosePhotoSubtitle;

  /// No description provided for @editProfileScreenCameraLabel.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get editProfileScreenCameraLabel;

  /// No description provided for @editProfileScreenTakePhotoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get editProfileScreenTakePhotoSubtitle;

  /// No description provided for @editProfileScreenPickFromLibrarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick from library'**
  String get editProfileScreenPickFromLibrarySubtitle;

  /// No description provided for @editProfileScreenRemoveCurrentPhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove current photo'**
  String get editProfileScreenRemoveCurrentPhoto;

  /// No description provided for @editProfileScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileScreenTitle;

  /// No description provided for @editProfileScreenBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get editProfileScreenBasicInfo;

  /// No description provided for @editProfileScreenFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get editProfileScreenFullName;

  /// No description provided for @editProfileScreenFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your display name'**
  String get editProfileScreenFullNameHint;

  /// No description provided for @editProfileScreenNameEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get editProfileScreenNameEmptyError;

  /// No description provided for @editProfileScreenUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Unique handle others can find you by'**
  String get editProfileScreenUsernameHint;

  /// No description provided for @editProfileScreenBio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get editProfileScreenBio;

  /// No description provided for @editProfileScreenBioHint.
  ///
  /// In en, this message translates to:
  /// **'A short line about you'**
  String get editProfileScreenBioHint;

  /// No description provided for @editProfileScreenLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Where you are'**
  String get editProfileScreenLocationHint;

  /// No description provided for @editProfileScreenEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get editProfileScreenEmail;

  /// No description provided for @editProfileScreenPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get editProfileScreenPhone;

  /// No description provided for @editProfileScreenEmailPhoneNotice.
  ///
  /// In en, this message translates to:
  /// **'Email and phone are tied to your sign-in and can\'t be edited here.'**
  String get editProfileScreenEmailPhoneNotice;

  /// No description provided for @editProfileScreenSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get editProfileScreenSaveChanges;

  /// No description provided for @editProfileScreenUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get editProfileScreenUploading;

  /// No description provided for @editProfileScreenChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get editProfileScreenChangePhoto;

  /// No description provided for @appearanceSettingsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSettingsScreenTitle;

  /// No description provided for @appearanceSettingsScreenInterfaceTheme.
  ///
  /// In en, this message translates to:
  /// **'Interface Theme'**
  String get appearanceSettingsScreenInterfaceTheme;

  /// No description provided for @appearanceSettingsScreenBrandPrimaryColor.
  ///
  /// In en, this message translates to:
  /// **'Brand Primary Color'**
  String get appearanceSettingsScreenBrandPrimaryColor;

  /// No description provided for @appearanceSettingsScreenBrandColorDesc.
  ///
  /// In en, this message translates to:
  /// **'Changes the highlights and action buttons across the app.'**
  String get appearanceSettingsScreenBrandColorDesc;

  /// No description provided for @appearanceSettingsScreenChatWallpaperStyle.
  ///
  /// In en, this message translates to:
  /// **'Chat Wallpaper & Style'**
  String get appearanceSettingsScreenChatWallpaperStyle;

  /// No description provided for @appearanceSettingsScreenColorBackdrop.
  ///
  /// In en, this message translates to:
  /// **'Color Backdrop'**
  String get appearanceSettingsScreenColorBackdrop;

  /// No description provided for @appearanceSettingsScreenBackgroundDoodles.
  ///
  /// In en, this message translates to:
  /// **'Background Doodles'**
  String get appearanceSettingsScreenBackgroundDoodles;

  /// No description provided for @appearanceSettingsScreenBackgroundDoodlesDesc.
  ///
  /// In en, this message translates to:
  /// **'Add subtle illustrations to flat colors.'**
  String get appearanceSettingsScreenBackgroundDoodlesDesc;

  /// No description provided for @appearanceSettingsScreenWallpaperGallery.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper Gallery'**
  String get appearanceSettingsScreenWallpaperGallery;

  /// No description provided for @appearanceSettingsScreenThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceSettingsScreenThemeLight;

  /// No description provided for @appearanceSettingsScreenThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceSettingsScreenThemeDark;

  /// No description provided for @appearanceSettingsScreenThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get appearanceSettingsScreenThemeSystem;

  /// No description provided for @appearanceSettingsScreenImageOpacity.
  ///
  /// In en, this message translates to:
  /// **'Image Opacity'**
  String get appearanceSettingsScreenImageOpacity;

  /// No description provided for @privacySettingsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get privacySettingsScreenTitle;

  /// No description provided for @privacySettingsScreenPrivateAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Private account'**
  String get privacySettingsScreenPrivateAccountTitle;

  /// No description provided for @privacySettingsScreenPrivateAccountDescPrivate.
  ///
  /// In en, this message translates to:
  /// **'Your account is Private. People who aren\'t your contacts have to send you a friend request before they can message you, call you, or see your stories.'**
  String get privacySettingsScreenPrivateAccountDescPrivate;

  /// No description provided for @privacySettingsScreenPrivateAccountDescPublic.
  ///
  /// In en, this message translates to:
  /// **'Your account is Public. Anyone on Talkmos can message you, call you, and see your stories.'**
  String get privacySettingsScreenPrivateAccountDescPublic;

  /// No description provided for @privacySettingsScreenPrivacyControls.
  ///
  /// In en, this message translates to:
  /// **'Privacy Controls'**
  String get privacySettingsScreenPrivacyControls;

  /// No description provided for @privacySettingsScreenReadReceipts.
  ///
  /// In en, this message translates to:
  /// **'Read Receipts'**
  String get privacySettingsScreenReadReceipts;

  /// No description provided for @privacySettingsScreenReadReceiptsDesc.
  ///
  /// In en, this message translates to:
  /// **'Let others know when you\'ve read their messages.'**
  String get privacySettingsScreenReadReceiptsDesc;

  /// No description provided for @privacySettingsScreenLastSeenOnline.
  ///
  /// In en, this message translates to:
  /// **'Last Seen & Online'**
  String get privacySettingsScreenLastSeenOnline;

  /// No description provided for @privacySettingsScreenLastSeenSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Who can see my last seen'**
  String get privacySettingsScreenLastSeenSheetTitle;

  /// No description provided for @privacySettingsScreenProfilePhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Photo'**
  String get privacySettingsScreenProfilePhotoTitle;

  /// No description provided for @privacySettingsScreenProfilePhotoSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Who can see my profile photo'**
  String get privacySettingsScreenProfilePhotoSheetTitle;

  /// No description provided for @privacySettingsScreenMedia.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get privacySettingsScreenMedia;

  /// No description provided for @privacySettingsScreenSaveToPhotos.
  ///
  /// In en, this message translates to:
  /// **'Save to Photos'**
  String get privacySettingsScreenSaveToPhotos;

  /// No description provided for @privacySettingsScreenSaveToPhotosDesc.
  ///
  /// In en, this message translates to:
  /// **'Save photos and videos you receive to this device\'s gallery, where other apps can see them. Off by default. Individual chats can override this.'**
  String get privacySettingsScreenSaveToPhotosDesc;

  /// No description provided for @privacySettingsScreenBlockedContacts.
  ///
  /// In en, this message translates to:
  /// **'Blocked Contacts'**
  String get privacySettingsScreenBlockedContacts;

  /// No description provided for @privacySettingsScreenBlockedCountNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get privacySettingsScreenBlockedCountNone;

  /// No description provided for @privacySettingsScreenBlockedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} blocked'**
  String privacySettingsScreenBlockedCount(int count);

  /// No description provided for @privacySettingsScreenLegalPolicy.
  ///
  /// In en, this message translates to:
  /// **'Legal & Policy'**
  String get privacySettingsScreenLegalPolicy;

  /// No description provided for @privacySettingsScreenPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacySettingsScreenPrivacyPolicy;

  /// No description provided for @privacySettingsScreenPrivacyPolicyDesc.
  ///
  /// In en, this message translates to:
  /// **'How your data is handled'**
  String get privacySettingsScreenPrivacyPolicyDesc;

  /// No description provided for @privacySettingsScreenTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get privacySettingsScreenTermsOfService;

  /// No description provided for @privacySettingsScreenTermsDesc.
  ///
  /// In en, this message translates to:
  /// **'The agreement you accepted at sign-up'**
  String get privacySettingsScreenTermsDesc;

  /// No description provided for @privacySettingsScreenGalleryPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Talkmos needs permission to add to your gallery. You can grant it in system settings.'**
  String get privacySettingsScreenGalleryPermissionNeeded;

  /// No description provided for @privacySettingsScreenSyncError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save that setting. Check your connection.'**
  String get privacySettingsScreenSyncError;

  /// No description provided for @privacySettingsScreenBrowserOpenError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the browser.'**
  String get privacySettingsScreenBrowserOpenError;

  /// No description provided for @privacySettingsScreenConnectionSecured.
  ///
  /// In en, this message translates to:
  /// **'Your connection is secured'**
  String get privacySettingsScreenConnectionSecured;

  /// No description provided for @privacySettingsScreenConnectionSecuredDesc.
  ///
  /// In en, this message translates to:
  /// **'Messages and calls travel over an encrypted connection, and only people in a chat can open it. Messages cached on this device are encrypted at rest.'**
  String get privacySettingsScreenConnectionSecuredDesc;

  /// No description provided for @profileScreenCheckingForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Checking for app updates...'**
  String get profileScreenCheckingForUpdates;

  /// No description provided for @profileScreenLatestVersion.
  ///
  /// In en, this message translates to:
  /// **'You are on the latest version of {appName}!'**
  String profileScreenLatestVersion(String appName);

  /// No description provided for @profileScreenComingSoon.
  ///
  /// In en, this message translates to:
  /// **'{feature} coming soon!'**
  String profileScreenComingSoon(String feature);

  /// No description provided for @profileScreenPrivacySecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get profileScreenPrivacySecurity;

  /// No description provided for @profileScreenDataAndStorage.
  ///
  /// In en, this message translates to:
  /// **'Data and Storage'**
  String get profileScreenDataAndStorage;

  /// No description provided for @profileScreenChatSettings.
  ///
  /// In en, this message translates to:
  /// **'Chat Settings'**
  String get profileScreenChatSettings;

  /// No description provided for @profileScreenLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileScreenLanguage;

  /// No description provided for @profileScreenHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get profileScreenHelpSupport;

  /// No description provided for @profileScreenCheckForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get profileScreenCheckForUpdates;

  /// No description provided for @profileScreenLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get profileScreenLogOut;

  /// No description provided for @profileScreenUserFallback.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get profileScreenUserFallback;

  /// No description provided for @profileScreenAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage your profile details'**
  String get profileScreenAccountDesc;

  /// No description provided for @profileScreenPrivacySecurityDesc.
  ///
  /// In en, this message translates to:
  /// **'Control who can see your info'**
  String get profileScreenPrivacySecurityDesc;

  /// No description provided for @profileScreenNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Message, group and call alerts'**
  String get profileScreenNotificationsDesc;

  /// No description provided for @profileScreenDataAndStorageDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage storage and media usage'**
  String get profileScreenDataAndStorageDesc;

  /// No description provided for @profileScreenChatSettingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper, themes and chat appearance'**
  String get profileScreenChatSettingsDesc;

  /// No description provided for @profileScreenDevicesDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage where you\'re logged in'**
  String get profileScreenDevicesDesc;

  /// No description provided for @profileScreenLanguageDesc.
  ///
  /// In en, this message translates to:
  /// **'Change the app\'s language'**
  String get profileScreenLanguageDesc;

  /// No description provided for @profileScreenCheckForUpdatesDesc.
  ///
  /// In en, this message translates to:
  /// **'Check if a new version is available'**
  String get profileScreenCheckForUpdatesDesc;

  /// No description provided for @profileScreenAboutDesc.
  ///
  /// In en, this message translates to:
  /// **'App info and legal details'**
  String get profileScreenAboutDesc;

  /// No description provided for @aboutScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutScreenTitle;

  /// No description provided for @aboutScreenVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String aboutScreenVersion(String version);

  /// No description provided for @aboutScreenLegalSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get aboutScreenLegalSectionTitle;

  /// No description provided for @aboutScreenTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get aboutScreenTermsOfService;

  /// No description provided for @aboutScreenPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get aboutScreenPrivacyPolicy;

  /// No description provided for @aboutScreenHelpSupportDesc.
  ///
  /// In en, this message translates to:
  /// **'Get help or contact us'**
  String get aboutScreenHelpSupportDesc;

  /// No description provided for @aboutScreenBrowserOpenError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the browser. Please try again.'**
  String get aboutScreenBrowserOpenError;

  /// No description provided for @aboutScreenCopyright.
  ///
  /// In en, this message translates to:
  /// **'© {year} {appName}. All rights reserved.'**
  String aboutScreenCopyright(String year, String appName);

  /// No description provided for @dataStorageSettingsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Data and Storage'**
  String get dataStorageSettingsScreenTitle;

  /// No description provided for @dataStorageSettingsScreenStorageHeader.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get dataStorageSettingsScreenStorageHeader;

  /// No description provided for @dataStorageSettingsScreenCachedMedia.
  ///
  /// In en, this message translates to:
  /// **'Cached media'**
  String get dataStorageSettingsScreenCachedMedia;

  /// No description provided for @dataStorageSettingsScreenClearing.
  ///
  /// In en, this message translates to:
  /// **'Clearing…'**
  String get dataStorageSettingsScreenClearing;

  /// No description provided for @dataStorageSettingsScreenTapToClear.
  ///
  /// In en, this message translates to:
  /// **'Tap to clear'**
  String get dataStorageSettingsScreenTapToClear;

  /// No description provided for @dataStorageSettingsScreenMeasuring.
  ///
  /// In en, this message translates to:
  /// **'Measuring…'**
  String get dataStorageSettingsScreenMeasuring;

  /// No description provided for @dataStorageSettingsScreenClearingSafeTitle.
  ///
  /// In en, this message translates to:
  /// **'Clearing is safe'**
  String get dataStorageSettingsScreenClearingSafeTitle;

  /// No description provided for @dataStorageSettingsScreenClearingSafeDesc.
  ///
  /// In en, this message translates to:
  /// **'Photos, videos and voice notes are re-downloaded from the server when you open them again. Your messages are stored separately and are never removed by this.'**
  String get dataStorageSettingsScreenClearingSafeDesc;

  /// No description provided for @dataStorageSettingsScreenMediaUpload.
  ///
  /// In en, this message translates to:
  /// **'Media Upload'**
  String get dataStorageSettingsScreenMediaUpload;

  /// No description provided for @dataStorageSettingsScreenUploadQuality.
  ///
  /// In en, this message translates to:
  /// **'Upload quality'**
  String get dataStorageSettingsScreenUploadQuality;

  /// No description provided for @dataStorageSettingsScreenAutomaticDownloads.
  ///
  /// In en, this message translates to:
  /// **'Automatic Downloads'**
  String get dataStorageSettingsScreenAutomaticDownloads;

  /// No description provided for @dataStorageSettingsScreenAutoSaveWifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Auto-save over Wi-Fi only'**
  String get dataStorageSettingsScreenAutoSaveWifiOnly;

  /// No description provided for @dataStorageSettingsScreenAutoSaveWifiOnlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Wait for Wi-Fi before saving received media to your gallery. Media you open is always downloaded, on any connection.'**
  String get dataStorageSettingsScreenAutoSaveWifiOnlyDesc;

  /// No description provided for @dataStorageSettingsScreenSaveToPhotos.
  ///
  /// In en, this message translates to:
  /// **'Save to Photos'**
  String get dataStorageSettingsScreenSaveToPhotos;

  /// No description provided for @dataStorageSettingsScreenOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get dataStorageSettingsScreenOn;

  /// No description provided for @dataStorageSettingsScreenOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get dataStorageSettingsScreenOff;

  /// No description provided for @dataStorageSettingsScreenNothingAutoSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing is being auto-saved'**
  String get dataStorageSettingsScreenNothingAutoSavedTitle;

  /// No description provided for @dataStorageSettingsScreenNothingAutoSavedDesc.
  ///
  /// In en, this message translates to:
  /// **'Save to Photos is off, so received media stays inside Talkmos and the Wi-Fi setting above has nothing to do yet. Individual chats can still opt in from their info page.'**
  String get dataStorageSettingsScreenNothingAutoSavedDesc;

  /// No description provided for @dataStorageSettingsScreenPhotoUploadQualityTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo upload quality'**
  String get dataStorageSettingsScreenPhotoUploadQualityTitle;

  /// No description provided for @dataStorageSettingsScreenRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get dataStorageSettingsScreenRecommended;

  /// No description provided for @dataStorageSettingsScreenQualityDataSaverDesc.
  ///
  /// In en, this message translates to:
  /// **'Smallest files, softest detail'**
  String get dataStorageSettingsScreenQualityDataSaverDesc;

  /// No description provided for @dataStorageSettingsScreenQualityStandardDesc.
  ///
  /// In en, this message translates to:
  /// **'Balanced — what Talkmos has always sent'**
  String get dataStorageSettingsScreenQualityStandardDesc;

  /// No description provided for @dataStorageSettingsScreenQualityHighDesc.
  ///
  /// In en, this message translates to:
  /// **'Sharpest detail, largest files'**
  String get dataStorageSettingsScreenQualityHighDesc;

  /// No description provided for @dataStorageSettingsScreenClearCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear cached media?'**
  String get dataStorageSettingsScreenClearCacheTitle;

  /// No description provided for @dataStorageSettingsScreenClearCacheDesc.
  ///
  /// In en, this message translates to:
  /// **'This frees up the space cached media is using{size}. Photos, videos and voice notes will be downloaded again the next time you open them. Your messages are not affected.'**
  String dataStorageSettingsScreenClearCacheDesc(String size);

  /// No description provided for @dataStorageSettingsScreenClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get dataStorageSettingsScreenClear;

  /// No description provided for @dataStorageSettingsScreenCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cached media cleared'**
  String get dataStorageSettingsScreenCacheCleared;

  /// No description provided for @helpSupportScreenFaq1Question.
  ///
  /// In en, this message translates to:
  /// **'How do I pin or unpin conversations?'**
  String get helpSupportScreenFaq1Question;

  /// No description provided for @helpSupportScreenFaq1Answer.
  ///
  /// In en, this message translates to:
  /// **'Go to the recent chat list on the Home screen. Long press on any conversation card and select \'Pin Conversation\' or \'Unpin Conversation\' from the pop-up options sheet. Pinned chats stay anchored at the top of your list.'**
  String get helpSupportScreenFaq1Answer;

  /// No description provided for @helpSupportScreenFaq2Question.
  ///
  /// In en, this message translates to:
  /// **'How do I record and send audio voice messages?'**
  String get helpSupportScreenFaq2Question;

  /// No description provided for @helpSupportScreenFaq2Answer.
  ///
  /// In en, this message translates to:
  /// **'Open any chat room. Tap and hold the mic icon in the message bar to record a voice note. The bar will show a recording duration and a cancel trigger. Releasing/sending will direct you to a premium preview page where you can review your WAV recording before sharing it.'**
  String get helpSupportScreenFaq2Answer;

  /// No description provided for @helpSupportScreenFaq3Question.
  ///
  /// In en, this message translates to:
  /// **'Where can I change the chat wallpaper backgrounds?'**
  String get helpSupportScreenFaq3Question;

  /// No description provided for @helpSupportScreenFaq3Answer.
  ///
  /// In en, this message translates to:
  /// **'Navigate to your Profile tab, tap \'Appearance\', and open the Chat Wallpaper customize panel. You can select custom solid backdrop colors or toggle background doodles on and off.'**
  String get helpSupportScreenFaq3Answer;

  /// No description provided for @helpSupportScreenFaq4Question.
  ///
  /// In en, this message translates to:
  /// **'How does message pinning work inside chat rooms?'**
  String get helpSupportScreenFaq4Question;

  /// No description provided for @helpSupportScreenFaq4Answer.
  ///
  /// In en, this message translates to:
  /// **'Inside any chat thread, single-tap a message bubble to view details and tap the Pin button in the AppBar. Pinned messages appear in a floating banner at the top of the chat room. Tapping it automatically scrolls you directly to that message.'**
  String get helpSupportScreenFaq4Answer;

  /// No description provided for @helpSupportScreenTicketSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Ticket Submitted'**
  String get helpSupportScreenTicketSubmittedTitle;

  /// No description provided for @helpSupportScreenTicketSubmittedBody.
  ///
  /// In en, this message translates to:
  /// **'Thank you for contacting Talkmos support. Your message has been sent successfully. Our team will review your report and respond shortly.'**
  String get helpSupportScreenTicketSubmittedBody;

  /// No description provided for @helpSupportScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupportScreenTitle;

  /// No description provided for @helpSupportScreenFaqHeading.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get helpSupportScreenFaqHeading;

  /// No description provided for @helpSupportScreenSubmitTicketHeading.
  ///
  /// In en, this message translates to:
  /// **'Submit a Support Ticket'**
  String get helpSupportScreenSubmitTicketHeading;

  /// No description provided for @helpSupportScreenSubjectLabel.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get helpSupportScreenSubjectLabel;

  /// No description provided for @helpSupportScreenSubjectHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Bug report, audio error'**
  String get helpSupportScreenSubjectHint;

  /// No description provided for @helpSupportScreenSubjectRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a subject'**
  String get helpSupportScreenSubjectRequired;

  /// No description provided for @helpSupportScreenDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description / Message'**
  String get helpSupportScreenDescriptionLabel;

  /// No description provided for @helpSupportScreenDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us how we can help you...'**
  String get helpSupportScreenDescriptionHint;

  /// No description provided for @helpSupportScreenDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Please describe your request'**
  String get helpSupportScreenDescriptionRequired;

  /// No description provided for @helpSupportScreenSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Submit Ticket'**
  String get helpSupportScreenSubmitButton;

  /// No description provided for @notificationsSettingsScreenAlertChannels.
  ///
  /// In en, this message translates to:
  /// **'Alert Channels'**
  String get notificationsSettingsScreenAlertChannels;

  /// No description provided for @notificationsSettingsScreenReceiveNotifications.
  ///
  /// In en, this message translates to:
  /// **'Receive Notifications'**
  String get notificationsSettingsScreenReceiveNotifications;

  /// No description provided for @notificationsSettingsScreenReceiveNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Get instant alerts for messages and updates.'**
  String get notificationsSettingsScreenReceiveNotificationsDesc;

  /// No description provided for @notificationsSettingsScreenMessageSound.
  ///
  /// In en, this message translates to:
  /// **'Message Sound'**
  String get notificationsSettingsScreenMessageSound;

  /// No description provided for @notificationsSettingsScreenVibrationAlerts.
  ///
  /// In en, this message translates to:
  /// **'Vibration Alerts'**
  String get notificationsSettingsScreenVibrationAlerts;

  /// No description provided for @notificationsSettingsScreenVibrationAlertsDesc.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback on every alert.'**
  String get notificationsSettingsScreenVibrationAlertsDesc;

  /// No description provided for @notificationsSettingsScreenMessagePreviews.
  ///
  /// In en, this message translates to:
  /// **'Message Previews'**
  String get notificationsSettingsScreenMessagePreviews;

  /// No description provided for @notificationsSettingsScreenMessagePreviewsDesc.
  ///
  /// In en, this message translates to:
  /// **'Show content on the lock screen.'**
  String get notificationsSettingsScreenMessagePreviewsDesc;

  /// No description provided for @notificationsSettingsScreenCallRingtone.
  ///
  /// In en, this message translates to:
  /// **'Call Ringtone'**
  String get notificationsSettingsScreenCallRingtone;

  /// No description provided for @notificationsSettingsScreenAudioToneNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Audio Tone Notice'**
  String get notificationsSettingsScreenAudioToneNoticeTitle;

  /// No description provided for @notificationsSettingsScreenAudioToneNoticeDesc.
  ///
  /// In en, this message translates to:
  /// **'Ringtone changes take effect on the next incoming call. Some tones may sound different depending on your device.'**
  String get notificationsSettingsScreenAudioToneNoticeDesc;

  /// No description provided for @notificationsSettingsScreenPrivateByDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Private by default'**
  String get notificationsSettingsScreenPrivateByDefaultTitle;

  /// No description provided for @notificationsSettingsScreenPrivateByDefaultDesc.
  ///
  /// In en, this message translates to:
  /// **'Only people in a chat can read its messages.'**
  String get notificationsSettingsScreenPrivateByDefaultDesc;

  /// No description provided for @blockedContactsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Blocked Contacts'**
  String get blockedContactsScreenTitle;

  /// No description provided for @blockedContactsScreenUnblockConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Unblock {name}?'**
  String blockedContactsScreenUnblockConfirmTitle(String name);

  /// No description provided for @blockedContactsScreenUnblockConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You will be able to message and call each other again.'**
  String get blockedContactsScreenUnblockConfirmBody;

  /// No description provided for @blockedContactsScreenUnblockFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to unblock: {error}'**
  String blockedContactsScreenUnblockFailed(String error);

  /// No description provided for @blockedContactsScreenEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No blocked contacts'**
  String get blockedContactsScreenEmptyTitle;

  /// No description provided for @blockedContactsScreenEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'People you block will no longer be able to message or call you.'**
  String get blockedContactsScreenEmptyDesc;

  /// No description provided for @selectContactScreenSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search name, username or phone...'**
  String get selectContactScreenSearchHint;

  /// No description provided for @selectContactScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Select contact'**
  String get selectContactScreenTitle;

  /// No description provided for @selectContactScreenLoadingContacts.
  ///
  /// In en, this message translates to:
  /// **'Loading contacts...'**
  String get selectContactScreenLoadingContacts;

  /// No description provided for @selectContactScreenContactCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} contact} other{{count} contacts}}'**
  String selectContactScreenContactCount(int count);

  /// No description provided for @selectContactScreenNewGroup.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get selectContactScreenNewGroup;

  /// No description provided for @selectContactScreenNewGroupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new group chat'**
  String get selectContactScreenNewGroupSubtitle;

  /// No description provided for @selectContactScreenNewContact.
  ///
  /// In en, this message translates to:
  /// **'New contact'**
  String get selectContactScreenNewContact;

  /// No description provided for @selectContactScreenNewContactSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a friend or find users'**
  String get selectContactScreenNewContactSubtitle;

  /// No description provided for @selectContactScreenContactsOnTalkmos.
  ///
  /// In en, this message translates to:
  /// **'Contacts on Talkmos'**
  String get selectContactScreenContactsOnTalkmos;

  /// No description provided for @selectContactScreenFindContactsOnTalkmos.
  ///
  /// In en, this message translates to:
  /// **'Find contacts on Talkmos'**
  String get selectContactScreenFindContactsOnTalkmos;

  /// No description provided for @selectContactScreenPermissionDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Contacts permission is off, so we can\'t show who you already know on Talkmos.'**
  String get selectContactScreenPermissionDeniedMessage;

  /// No description provided for @selectContactScreenTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get selectContactScreenTryAgain;

  /// No description provided for @selectContactScreenNoMatchingContacts.
  ///
  /// In en, this message translates to:
  /// **'No matching contacts'**
  String get selectContactScreenNoMatchingContacts;

  /// No description provided for @selectContactScreenNothingToShowYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show yet'**
  String get selectContactScreenNothingToShowYet;

  /// No description provided for @selectContactScreenNoPhoneContactsMatch.
  ///
  /// In en, this message translates to:
  /// **'No phone contacts match \"{query}\".'**
  String selectContactScreenNoPhoneContactsMatch(String query);

  /// No description provided for @selectContactScreenIndianNumbersOnly.
  ///
  /// In en, this message translates to:
  /// **'We only list Indian mobile numbers saved on this phone. Save a contact, then refresh to see them here.'**
  String get selectContactScreenIndianNumbersOnly;

  /// No description provided for @selectContactScreenClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get selectContactScreenClearSearch;

  /// No description provided for @selectContactScreenRefreshContacts.
  ///
  /// In en, this message translates to:
  /// **'Refresh contacts'**
  String get selectContactScreenRefreshContacts;

  /// No description provided for @selectContactScreenFromYourContacts.
  ///
  /// In en, this message translates to:
  /// **'FROM YOUR CONTACTS'**
  String get selectContactScreenFromYourContacts;

  /// No description provided for @selectContactScreenInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get selectContactScreenInvite;

  /// No description provided for @selectContactScreenAddFriendTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add friend'**
  String get selectContactScreenAddFriendTooltip;

  /// No description provided for @selectContactScreenRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get selectContactScreenRequested;

  /// No description provided for @selectContactScreenWantsToConnect.
  ///
  /// In en, this message translates to:
  /// **'Wants to connect'**
  String get selectContactScreenWantsToConnect;

  /// No description provided for @selectContactScreenCouldNotOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Could not open chat: {error}'**
  String selectContactScreenCouldNotOpenChat(String error);

  /// No description provided for @selectContactScreenFriendRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent'**
  String get selectContactScreenFriendRequestSent;

  /// No description provided for @selectContactScreenCouldNotSendRequest.
  ///
  /// In en, this message translates to:
  /// **'Could not send request: {error}'**
  String selectContactScreenCouldNotSendRequest(String error);

  /// No description provided for @selectContactScreenInviteMessage.
  ///
  /// In en, this message translates to:
  /// **'Join me on Talkmos — https://talkmos.com'**
  String get selectContactScreenInviteMessage;

  /// No description provided for @selectContactScreenNoMessagingApp.
  ///
  /// In en, this message translates to:
  /// **'No messaging app available'**
  String get selectContactScreenNoMessagingApp;

  /// No description provided for @selectContactScreenCouldNotOpenMessagingApp.
  ///
  /// In en, this message translates to:
  /// **'Could not open messaging app'**
  String get selectContactScreenCouldNotOpenMessagingApp;

  /// No description provided for @selectContactScreenDefaultStatus.
  ///
  /// In en, this message translates to:
  /// **'Hey there! I am using Talkmos'**
  String get selectContactScreenDefaultStatus;

  /// No description provided for @selectContactScreenNoContactsFound.
  ///
  /// In en, this message translates to:
  /// **'No contacts found'**
  String get selectContactScreenNoContactsFound;

  /// No description provided for @selectContactScreenNoFriendsFoundMatching.
  ///
  /// In en, this message translates to:
  /// **'No friends found matching \"{query}\".'**
  String selectContactScreenNoFriendsFoundMatching(String query);

  /// No description provided for @selectContactScreenAddFriendsToStartChatting.
  ///
  /// In en, this message translates to:
  /// **'Add friends or search for people on Talkmos to start chatting.'**
  String get selectContactScreenAddFriendsToStartChatting;

  /// No description provided for @selectContactScreenFindContacts.
  ///
  /// In en, this message translates to:
  /// **'Find Contacts'**
  String get selectContactScreenFindContacts;

  /// No description provided for @userProfileScreenStartConversationBeforeMedia.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation before viewing shared media.'**
  String get userProfileScreenStartConversationBeforeMedia;

  /// No description provided for @userProfileScreenStartConversationBeforeMuting.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation before muting it.'**
  String get userProfileScreenStartConversationBeforeMuting;

  /// No description provided for @userProfileScreenStartConversationBeforeChanging.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation before changing this.'**
  String get userProfileScreenStartConversationBeforeChanging;

  /// No description provided for @userProfileScreenCouldNotOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Could not open chat: {error}'**
  String userProfileScreenCouldNotOpenChat(String error);

  /// No description provided for @userProfileScreenFailedToStartCall.
  ///
  /// In en, this message translates to:
  /// **'Failed to start call: {error}'**
  String userProfileScreenFailedToStartCall(String error);

  /// No description provided for @userProfileScreenMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get userProfileScreenMessage;

  /// No description provided for @userProfileScreenAudioCall.
  ///
  /// In en, this message translates to:
  /// **'Audio Call'**
  String get userProfileScreenAudioCall;

  /// No description provided for @userProfileScreenVideoCall.
  ///
  /// In en, this message translates to:
  /// **'Video Call'**
  String get userProfileScreenVideoCall;

  /// No description provided for @userProfileScreenAddFriend.
  ///
  /// In en, this message translates to:
  /// **'Add Friend'**
  String get userProfileScreenAddFriend;

  /// No description provided for @userProfileScreenRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get userProfileScreenRequested;

  /// No description provided for @userProfileScreenAcceptRequest.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get userProfileScreenAcceptRequest;

  /// No description provided for @userProfileScreenRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent'**
  String get userProfileScreenRequestSent;

  /// No description provided for @userProfileScreenRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Friend request accepted'**
  String get userProfileScreenRequestAccepted;

  /// No description provided for @userProfileScreenRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the request: {error}'**
  String userProfileScreenRequestFailed(String error);

  /// No description provided for @userProfileScreenTalkmosUsername.
  ///
  /// In en, this message translates to:
  /// **'Talkmos Username'**
  String get userProfileScreenTalkmosUsername;

  /// No description provided for @userProfileScreenUsernameCopied.
  ///
  /// In en, this message translates to:
  /// **'Username copied'**
  String get userProfileScreenUsernameCopied;

  /// No description provided for @userProfileScreenPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get userProfileScreenPhone;

  /// No description provided for @userProfileScreenPhoneNumberCopied.
  ///
  /// In en, this message translates to:
  /// **'Phone number copied'**
  String get userProfileScreenPhoneNumberCopied;

  /// No description provided for @userProfileScreenSharedMedia.
  ///
  /// In en, this message translates to:
  /// **'Shared Media'**
  String get userProfileScreenSharedMedia;

  /// No description provided for @userProfileScreenMuted.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get userProfileScreenMuted;

  /// No description provided for @userProfileScreenOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get userProfileScreenOn;

  /// No description provided for @userProfileScreenMediaVisibility.
  ///
  /// In en, this message translates to:
  /// **'Media Visibility'**
  String get userProfileScreenMediaVisibility;

  /// No description provided for @userProfileScreenUnblockContact.
  ///
  /// In en, this message translates to:
  /// **'Unblock Contact'**
  String get userProfileScreenUnblockContact;

  /// No description provided for @userProfileScreenBlockContact.
  ///
  /// In en, this message translates to:
  /// **'Block Contact'**
  String get userProfileScreenBlockContact;

  /// No description provided for @userProfileScreenDefaultBio.
  ///
  /// In en, this message translates to:
  /// **'Hey there! I am using Talkmos'**
  String get userProfileScreenDefaultBio;

  /// No description provided for @userProfileScreenUnblockConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Unblock {name}?'**
  String userProfileScreenUnblockConfirmTitle(String name);

  /// No description provided for @userProfileScreenBlockConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Block {name}?'**
  String userProfileScreenBlockConfirmTitle(String name);

  /// No description provided for @userProfileScreenUnblockConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You will be able to message and call each other again.'**
  String get userProfileScreenUnblockConfirmBody;

  /// No description provided for @userProfileScreenBlockConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'They will no longer be able to message or call you, and you won\'t be able to message or call them either.'**
  String get userProfileScreenBlockConfirmBody;

  /// No description provided for @userProfileScreenUnblockedToast.
  ///
  /// In en, this message translates to:
  /// **'{name} unblocked'**
  String userProfileScreenUnblockedToast(String name);

  /// No description provided for @userProfileScreenBlockedToast.
  ///
  /// In en, this message translates to:
  /// **'{name} blocked'**
  String userProfileScreenBlockedToast(String name);

  /// No description provided for @userProfileScreenFailedToUpdateBlockStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to update block status: {error}'**
  String userProfileScreenFailedToUpdateBlockStatus(String error);

  /// No description provided for @userProfileScreenShareContact.
  ///
  /// In en, this message translates to:
  /// **'Share Contact'**
  String get userProfileScreenShareContact;

  /// No description provided for @userProfileScreenContactCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Contact copied to clipboard'**
  String get userProfileScreenContactCopiedToClipboard;

  /// No description provided for @activeCallScreenAddToCall.
  ///
  /// In en, this message translates to:
  /// **'Add to Call'**
  String get activeCallScreenAddToCall;

  /// No description provided for @activeCallScreenShareScreen.
  ///
  /// In en, this message translates to:
  /// **'Share Screen'**
  String get activeCallScreenShareScreen;

  /// No description provided for @activeCallScreenStopSharingScreen.
  ///
  /// In en, this message translates to:
  /// **'Stop Sharing'**
  String get activeCallScreenStopSharingScreen;

  /// No description provided for @activeCallScreenNoFriendsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No friends available to invite'**
  String get activeCallScreenNoFriendsAvailable;

  /// No description provided for @activeCallScreenNoContactsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No one available to invite'**
  String get activeCallScreenNoContactsAvailable;

  /// No description provided for @activeCallScreenCallingName.
  ///
  /// In en, this message translates to:
  /// **'Calling {name}…'**
  String activeCallScreenCallingName(String name);

  /// No description provided for @activeCallScreenConnectingVideoWith.
  ///
  /// In en, this message translates to:
  /// **'Connecting video with {name}...'**
  String activeCallScreenConnectingVideoWith(String name);

  /// No description provided for @activeCallScreenReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get activeCallScreenReconnecting;

  /// No description provided for @activeCallScreenCameraOff.
  ///
  /// In en, this message translates to:
  /// **'Camera off'**
  String get activeCallScreenCameraOff;

  /// No description provided for @activeCallScreenCalling.
  ///
  /// In en, this message translates to:
  /// **'Calling...'**
  String get activeCallScreenCalling;

  /// No description provided for @activeCallScreenRinging.
  ///
  /// In en, this message translates to:
  /// **'Ringing...'**
  String get activeCallScreenRinging;

  /// No description provided for @activeCallScreenEncryptedCall.
  ///
  /// In en, this message translates to:
  /// **'Encrypted Call'**
  String get activeCallScreenEncryptedCall;

  /// No description provided for @activeCallScreenStartVideo.
  ///
  /// In en, this message translates to:
  /// **'Start Video'**
  String get activeCallScreenStartVideo;

  /// No description provided for @activeCallScreenStopVideo.
  ///
  /// In en, this message translates to:
  /// **'Stop Video'**
  String get activeCallScreenStopVideo;

  /// No description provided for @activeCallScreenMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get activeCallScreenMore;

  /// No description provided for @activeCallScreenEndCall.
  ///
  /// In en, this message translates to:
  /// **'End Call'**
  String get activeCallScreenEndCall;

  /// No description provided for @activeCallBannerTapToReturn.
  ///
  /// In en, this message translates to:
  /// **'Tap to return to call'**
  String get activeCallBannerTapToReturn;

  /// No description provided for @activeCallBannerOngoingCall.
  ///
  /// In en, this message translates to:
  /// **'Ongoing call'**
  String get activeCallBannerOngoingCall;

  /// No description provided for @friendRequestsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Friend Requests'**
  String get friendRequestsScreenTitle;

  /// No description provided for @friendRequestsScreenReceivedTab.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get friendRequestsScreenReceivedTab;

  /// No description provided for @friendRequestsScreenSentTab.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get friendRequestsScreenSentTab;

  /// No description provided for @friendRequestsScreenSectionSent.
  ///
  /// In en, this message translates to:
  /// **'Requests you\'ve sent'**
  String get friendRequestsScreenSectionSent;

  /// No description provided for @friendRequestsScreenSectionReceived.
  ///
  /// In en, this message translates to:
  /// **'Requests you\'ve received'**
  String get friendRequestsScreenSectionReceived;

  /// No description provided for @friendRequestsScreenNoReceived.
  ///
  /// In en, this message translates to:
  /// **'No pending received requests.'**
  String get friendRequestsScreenNoReceived;

  /// No description provided for @friendRequestsScreenNoSent.
  ///
  /// In en, this message translates to:
  /// **'No pending sent requests.'**
  String get friendRequestsScreenNoSent;

  /// No description provided for @friendRequestsScreenDefaultUserName.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get friendRequestsScreenDefaultUserName;

  /// No description provided for @friendRequestsScreenPrivacyHint.
  ///
  /// In en, this message translates to:
  /// **'Only accept requests from people you know and trust.'**
  String get friendRequestsScreenPrivacyHint;

  /// No description provided for @friendRequestsScreenLearnMorePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Learn more about privacy >'**
  String get friendRequestsScreenLearnMorePrivacy;

  /// No description provided for @friendRequestsScreenAcceptError.
  ///
  /// In en, this message translates to:
  /// **'Could not accept request: {error}'**
  String friendRequestsScreenAcceptError(String error);

  /// No description provided for @friendRequestsScreenPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get friendRequestsScreenPending;

  /// No description provided for @userSearchScreenPrivateAccount.
  ///
  /// In en, this message translates to:
  /// **'This account is private. Send a friend request to see their profile.'**
  String get userSearchScreenPrivateAccount;

  /// No description provided for @userSearchScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Find Contacts'**
  String get userSearchScreenTitle;

  /// No description provided for @userSearchScreenSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, email or phone...'**
  String get userSearchScreenSearchHint;

  /// No description provided for @userSearchScreenBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Search users by Talkmos ID'**
  String get userSearchScreenBannerTitle;

  /// No description provided for @userSearchScreenBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can find people using their Talkmos ID'**
  String get userSearchScreenBannerSubtitle;

  /// No description provided for @userSearchScreenEmptyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Search for people to chat with'**
  String get userSearchScreenEmptyPrompt;

  /// No description provided for @userSearchScreenNoResults.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get userSearchScreenNoResults;

  /// No description provided for @userSearchScreenResultsHeader.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get userSearchScreenResultsHeader;

  /// No description provided for @userSearchScreenDefaultUserName.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userSearchScreenDefaultUserName;

  /// No description provided for @userSearchScreenFriendStatus.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get userSearchScreenFriendStatus;

  /// No description provided for @userSearchScreenPendingStatus.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get userSearchScreenPendingStatus;

  /// No description provided for @userSearchScreenRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Friend request accepted!'**
  String get userSearchScreenRequestAccepted;

  /// No description provided for @userSearchScreenRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent!'**
  String get userSearchScreenRequestSent;

  /// No description provided for @userSearchScreenSendRequestError.
  ///
  /// In en, this message translates to:
  /// **'Could not send request: {error}'**
  String userSearchScreenSendRequestError(String error);

  /// No description provided for @callsScreenAm.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get callsScreenAm;

  /// No description provided for @callsScreenPm.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get callsScreenPm;

  /// No description provided for @callsScreenWeekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get callsScreenWeekdayMon;

  /// No description provided for @callsScreenWeekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get callsScreenWeekdayTue;

  /// No description provided for @callsScreenWeekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get callsScreenWeekdayWed;

  /// No description provided for @callsScreenWeekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get callsScreenWeekdayThu;

  /// No description provided for @callsScreenWeekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get callsScreenWeekdayFri;

  /// No description provided for @callsScreenWeekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get callsScreenWeekdaySat;

  /// No description provided for @callsScreenWeekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get callsScreenWeekdaySun;

  /// No description provided for @callsScreenNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No call history found.'**
  String get callsScreenNoHistory;

  /// No description provided for @callsScreenNoMissedCalls.
  ///
  /// In en, this message translates to:
  /// **'No missed calls.'**
  String get callsScreenNoMissedCalls;

  /// No description provided for @callsScreenNoIncomingCalls.
  ///
  /// In en, this message translates to:
  /// **'No incoming calls.'**
  String get callsScreenNoIncomingCalls;

  /// No description provided for @callsScreenNoOutgoingCalls.
  ///
  /// In en, this message translates to:
  /// **'No outgoing calls.'**
  String get callsScreenNoOutgoingCalls;

  /// No description provided for @callsScreenNoSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No calls found'**
  String get callsScreenNoSearchResults;

  /// No description provided for @callsScreenOlder.
  ///
  /// In en, this message translates to:
  /// **'Older'**
  String get callsScreenOlder;

  /// No description provided for @callsScreenFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get callsScreenFilterAll;

  /// No description provided for @callsScreenFilterMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get callsScreenFilterMissed;

  /// No description provided for @callsScreenFilterIncoming.
  ///
  /// In en, this message translates to:
  /// **'Incoming'**
  String get callsScreenFilterIncoming;

  /// No description provided for @callsScreenFilterOutgoing.
  ///
  /// In en, this message translates to:
  /// **'Outgoing'**
  String get callsScreenFilterOutgoing;

  /// No description provided for @callsScreenDefaultUserName.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get callsScreenDefaultUserName;

  /// No description provided for @callsScreenCannotPlaceCallMissingDetails.
  ///
  /// In en, this message translates to:
  /// **'Cannot place call: User details missing'**
  String get callsScreenCannotPlaceCallMissingDetails;

  /// No description provided for @callsScreenCannotPlaceCallGroupNotFound.
  ///
  /// In en, this message translates to:
  /// **'Cannot place call: Group conversation not found'**
  String get callsScreenCannotPlaceCallGroupNotFound;

  /// No description provided for @callsScreenCannotPlaceCallChatNotFound.
  ///
  /// In en, this message translates to:
  /// **'Cannot place call: Chat not found'**
  String get callsScreenCannotPlaceCallChatNotFound;

  /// No description provided for @callsScreenFailedToStartCall.
  ///
  /// In en, this message translates to:
  /// **'Failed to start call: {error}'**
  String callsScreenFailedToStartCall(String error);

  /// No description provided for @soundSelectorRowIncludedWithTalkmos.
  ///
  /// In en, this message translates to:
  /// **'Included with Talkmos'**
  String get soundSelectorRowIncludedWithTalkmos;

  /// No description provided for @soundSelectorRowPhoneDefault.
  ///
  /// In en, this message translates to:
  /// **'Phone default'**
  String get soundSelectorRowPhoneDefault;

  /// No description provided for @soundSelectorRowFollowPhoneTone.
  ///
  /// In en, this message translates to:
  /// **'Follow this phone\'s own tone'**
  String get soundSelectorRowFollowPhoneTone;

  /// No description provided for @soundSelectorRowChooseFromDevice.
  ///
  /// In en, this message translates to:
  /// **'Choose from device'**
  String get soundSelectorRowChooseFromDevice;

  /// No description provided for @soundSelectorRowPickAnyTone.
  ///
  /// In en, this message translates to:
  /// **'Pick any tone on this phone'**
  String get soundSelectorRowPickAnyTone;

  /// No description provided for @soundSelectorRowSilentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show the notification without a sound'**
  String get soundSelectorRowSilentSubtitle;

  /// No description provided for @communityScreenJoinedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully joined community!'**
  String get communityScreenJoinedSuccess;

  /// No description provided for @communityScreenJoinError.
  ///
  /// In en, this message translates to:
  /// **'Error joining: {error}'**
  String communityScreenJoinError(String error);

  /// No description provided for @communityScreenDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get communityScreenDefaultName;

  /// No description provided for @communityScreenSearchComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Community search coming soon!'**
  String get communityScreenSearchComingSoon;

  /// No description provided for @communityScreenNotificationsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Notifications coming soon.'**
  String get communityScreenNotificationsComingSoon;

  /// No description provided for @communityScreenYourCommunities.
  ///
  /// In en, this message translates to:
  /// **'Your communities'**
  String get communityScreenYourCommunities;

  /// No description provided for @communityScreenDiscoverSection.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get communityScreenDiscoverSection;

  /// No description provided for @communityScreenLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load communities'**
  String get communityScreenLoadError;

  /// No description provided for @communityScreenNewCommunity.
  ///
  /// In en, this message translates to:
  /// **'New community'**
  String get communityScreenNewCommunity;

  /// No description provided for @communityScreenUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get communityScreenUntitled;

  /// No description provided for @communityScreenAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get communityScreenAnnouncements;

  /// No description provided for @communityScreenMembersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} member} other{{count} members}}'**
  String communityScreenMembersCount(int count);

  /// No description provided for @communityScreenNoDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get communityScreenNoDescription;

  /// No description provided for @communityScreenPreviewPhoto.
  ///
  /// In en, this message translates to:
  /// **'📷 Photo'**
  String get communityScreenPreviewPhoto;

  /// No description provided for @communityScreenPreviewVideo.
  ///
  /// In en, this message translates to:
  /// **'🎥 Video'**
  String get communityScreenPreviewVideo;

  /// No description provided for @communityScreenPreviewAudio.
  ///
  /// In en, this message translates to:
  /// **'🎵 Audio'**
  String get communityScreenPreviewAudio;

  /// No description provided for @communityScreenPreviewFile.
  ///
  /// In en, this message translates to:
  /// **'📄 File'**
  String get communityScreenPreviewFile;

  /// No description provided for @communityScreenJoinedLabel.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get communityScreenJoinedLabel;

  /// No description provided for @communityScreenJoinButton.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get communityScreenJoinButton;

  /// No description provided for @communityScreenIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Introduce communities'**
  String get communityScreenIntroTitle;

  /// No description provided for @communityScreenIntroBody.
  ///
  /// In en, this message translates to:
  /// **'Communities bring members together in topic-based groups, and make it easy to get relevant announcements.'**
  String get communityScreenIntroBody;

  /// No description provided for @communityScreenStartButton.
  ///
  /// In en, this message translates to:
  /// **'Start your community'**
  String get communityScreenStartButton;

  /// No description provided for @communityScreenImageUploadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image: {error}'**
  String communityScreenImageUploadError(String error);

  /// No description provided for @communityScreenCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Community created successfully!'**
  String get communityScreenCreateSuccess;

  /// No description provided for @communityScreenNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Community name'**
  String get communityScreenNameLabel;

  /// No description provided for @communityScreenDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get communityScreenDescriptionLabel;

  /// No description provided for @communityScreenCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get communityScreenCategoryLabel;

  /// No description provided for @communityScreenCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create Community'**
  String get communityScreenCreateButton;

  /// No description provided for @communityDetailScreenLeaveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to leave: {error}'**
  String communityDetailScreenLeaveError(String error);

  /// No description provided for @communityDetailScreenLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave community?'**
  String get communityDetailScreenLeaveTitle;

  /// No description provided for @communityDetailScreenLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll stop receiving messages from {name}.'**
  String communityDetailScreenLeaveBody(String name);

  /// No description provided for @communityDetailScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Community Info'**
  String get communityDetailScreenTitle;

  /// No description provided for @communityDetailScreenShareInvite.
  ///
  /// In en, this message translates to:
  /// **'Share invite link'**
  String get communityDetailScreenShareInvite;

  /// No description provided for @communityDetailScreenLeaveButton.
  ///
  /// In en, this message translates to:
  /// **'Leave Community'**
  String get communityDetailScreenLeaveButton;

  /// No description provided for @communityDetailScreenMembersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} member} other{{count} members}}'**
  String communityDetailScreenMembersCount(int count);

  /// No description provided for @communityDetailScreenMembersHeader.
  ///
  /// In en, this message translates to:
  /// **'MEMBERS'**
  String get communityDetailScreenMembersHeader;

  /// No description provided for @communityDetailScreenMembersHeaderCount.
  ///
  /// In en, this message translates to:
  /// **'MEMBERS ({count})'**
  String communityDetailScreenMembersHeaderCount(int count);

  /// No description provided for @communityDetailScreenMembersLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load members: {error}'**
  String communityDetailScreenMembersLoadError(String error);

  /// No description provided for @createStoryScreenCameraPhoto.
  ///
  /// In en, this message translates to:
  /// **'Camera photo'**
  String get createStoryScreenCameraPhoto;

  /// No description provided for @createStoryScreenCameraVideo.
  ///
  /// In en, this message translates to:
  /// **'Camera video'**
  String get createStoryScreenCameraVideo;

  /// No description provided for @createStoryScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'New Status'**
  String get createStoryScreenTitle;

  /// No description provided for @createStoryScreenTitleWithCount.
  ///
  /// In en, this message translates to:
  /// **'New Status ({count})'**
  String createStoryScreenTitleWithCount(int count);

  /// No description provided for @createStoryScreenAddMoreTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add more'**
  String get createStoryScreenAddMoreTooltip;

  /// No description provided for @createStoryScreenShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get createStoryScreenShare;

  /// No description provided for @createStoryScreenPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Share a photo or video status'**
  String get createStoryScreenPickerTitle;

  /// No description provided for @createStoryScreenPickerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick multiple to post them all at once'**
  String get createStoryScreenPickerSubtitle;

  /// No description provided for @createStoryScreenPhotoOption.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get createStoryScreenPhotoOption;

  /// No description provided for @createStoryScreenCaptionHint.
  ///
  /// In en, this message translates to:
  /// **'Add a caption…'**
  String get createStoryScreenCaptionHint;

  /// No description provided for @createStoryScreenAddStickerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add Sticker'**
  String get createStoryScreenAddStickerTooltip;

  /// No description provided for @createStoryScreenFilterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get createStoryScreenFilterTooltip;

  /// No description provided for @storyViewerScreenVideoLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load video'**
  String get storyViewerScreenVideoLoadError;

  /// No description provided for @storyViewerScreenDeleteStory.
  ///
  /// In en, this message translates to:
  /// **'Delete status'**
  String get storyViewerScreenDeleteStory;

  /// No description provided for @storyViewerScreenDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this status? People who haven\'t seen it won\'t be able to.'**
  String get storyViewerScreenDeleteConfirm;

  /// No description provided for @storyViewerScreenDeleted.
  ///
  /// In en, this message translates to:
  /// **'Status deleted'**
  String get storyViewerScreenDeleted;

  /// No description provided for @storyViewerScreenDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete this status'**
  String get storyViewerScreenDeleteFailed;

  /// No description provided for @mainNavigationNewGroup.
  ///
  /// In en, this message translates to:
  /// **'New Group'**
  String get mainNavigationNewGroup;

  /// No description provided for @mainNavigationFindContacts.
  ///
  /// In en, this message translates to:
  /// **'Find Contacts'**
  String get mainNavigationFindContacts;

  /// No description provided for @mainNavigationFriendRequests.
  ///
  /// In en, this message translates to:
  /// **'Friend Requests'**
  String get mainNavigationFriendRequests;

  /// No description provided for @mainNavigationSavedMessages.
  ///
  /// In en, this message translates to:
  /// **'Saved Messages'**
  String get mainNavigationSavedMessages;

  /// No description provided for @mainNavigationLightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get mainNavigationLightMode;

  /// No description provided for @mainNavigationDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get mainNavigationDarkMode;

  /// No description provided for @mainNavigationInviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get mainNavigationInviteFriends;

  /// No description provided for @mainNavigationLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get mainNavigationLogout;

  /// No description provided for @mainNavigationGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get mainNavigationGuest;

  /// No description provided for @mainNavigationChatsTab.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get mainNavigationChatsTab;

  /// No description provided for @privacySettingsScreenVisibilityContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get privacySettingsScreenVisibilityContacts;

  /// No description provided for @privacySettingsScreenVisibilityNobody.
  ///
  /// In en, this message translates to:
  /// **'Nobody'**
  String get privacySettingsScreenVisibilityNobody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
