// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get commonAppName => 'Talkmos';

  @override
  String get commonCancel => 'रद्द करें';

  @override
  String get commonSave => 'सेव करें';

  @override
  String get commonDelete => 'हटाएं';

  @override
  String get commonEdit => 'संपादित करें';

  @override
  String get commonAdd => 'जोड़ें';

  @override
  String get commonRemove => 'हटाएं';

  @override
  String get commonRetry => 'फिर कोशिश करें';

  @override
  String get commonClose => 'बंद करें';

  @override
  String get commonDone => 'हो गया';

  @override
  String get commonOk => 'ठीक है';

  @override
  String get commonYes => 'हां';

  @override
  String get commonNo => 'नहीं';

  @override
  String get commonSend => 'भेजें';

  @override
  String get commonSearch => 'खोजें';

  @override
  String get commonBlock => 'ब्लॉक करें';

  @override
  String get commonUnblock => 'अनब्लॉक करें';

  @override
  String get commonMute => 'म्यूट करें';

  @override
  String get commonUnmute => 'अनम्यूट करें';

  @override
  String get commonLeave => 'छोड़ें';

  @override
  String get commonAccept => 'स्वीकार करें';

  @override
  String get commonDecline => 'अस्वीकार करें';

  @override
  String get commonToday => 'आज';

  @override
  String get commonYesterday => 'कल';

  @override
  String get commonLoading => 'लोड हो रहा है…';

  @override
  String get commonUnknown => 'अज्ञात';

  @override
  String get commonMe => 'मैं';

  @override
  String get commonYou => 'आप';

  @override
  String get commonSettings => 'सेटिंग्स';

  @override
  String get commonMembers => 'सदस्य';

  @override
  String get commonMember => 'सदस्य';

  @override
  String get commonOpen => 'खोलें';

  @override
  String get commonAdmin => 'एडमिन';

  @override
  String get commonAdmins => 'एडमिन';

  @override
  String get commonEveryone => 'सभी';

  @override
  String get commonSomeone => 'कोई';

  @override
  String get commonSilent => 'मौन';

  @override
  String get commonUsername => 'यूज़रनेम';

  @override
  String get commonPassword => 'पासवर्ड';

  @override
  String get commonAbout => 'परिचय';

  @override
  String get commonPermissions => 'अनुमतियां';

  @override
  String get commonMessages => 'मैसेज';

  @override
  String get commonCalls => 'कॉल';

  @override
  String get commonChat => 'चैट';

  @override
  String get commonGallery => 'गैलरी';

  @override
  String get commonLocation => 'लोकेशन';

  @override
  String get commonVideo => 'वीडियो';

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
  String get commonFriends => 'दोस्त';

  @override
  String get commonDevices => 'डिवाइस';

  @override
  String get devicesScreenTitle => 'डिवाइस';

  @override
  String get devicesScreenBannerTitle => 'अपने अकाउंट को सुरक्षित रखें';

  @override
  String get devicesScreenBannerMessage =>
      'ये वे डिवाइस हैं जो फ़िलहाल आपके अकाउंट में साइन इन हैं। अगर कोई डिवाइस अनजान लगे, तो उसे तुरंत लॉग आउट करें।';

  @override
  String get devicesScreenThisDevice => 'यह डिवाइस';

  @override
  String get devicesScreenActiveNow => 'अभी सक्रिय';

  @override
  String devicesScreenLastActive(String date) {
    return 'अंतिम सक्रियता $date';
  }

  @override
  String devicesScreenLoggedOutOn(String date) {
    return '$date को लॉग आउट हुआ';
  }

  @override
  String get devicesScreenLogOut => 'लॉग आउट';

  @override
  String get devicesScreenLogOutConfirmTitle => 'इस डिवाइस को लॉग आउट करें?';

  @override
  String devicesScreenLogOutConfirmMessage(String deviceName) {
    return '$deviceName को तुरंत साइन आउट कर दिया जाएगा।';
  }

  @override
  String devicesScreenLogOutFailed(String error) {
    return 'डिवाइस लॉग आउट करने में विफल: $error';
  }

  @override
  String get devicesScreenLoggedOut => 'डिवाइस लॉग आउट हो गया';

  @override
  String devicesScreenLoadFailed(String error) {
    return 'डिवाइस लोड करने में विफल: $error';
  }

  @override
  String get devicesScreenNoDevices => 'कोई डिवाइस नहीं मिला';

  @override
  String get commonAccount => 'अकाउंट';

  @override
  String get commonNotifications => 'सूचनाएं';

  @override
  String get commonSpeaker => 'स्पीकर';

  @override
  String get languageSettingsTitle => 'भाषा';

  @override
  String get languageSettingsSectionHeader => 'ऐप की भाषा';

  @override
  String get languageSettingsFollowDevice => 'डिवाइस की भाषा के अनुसार';

  @override
  String get languageSettingsNoticeTitle => 'अनुवाद सूचना';

  @override
  String get languageSettingsNoticeBody =>
      'ऐप के कुछ नए हिस्से तब तक अंग्रेज़ी में दिख सकते हैं जब तक उनका अनुवाद नहीं जोड़ा जाता।';

  @override
  String get chatScreenGroupDeletedByOwner =>
      'इस समूह को इसके मालिक ने हटा दिया है';

  @override
  String get chatScreenDeleteMessageTitle => 'संदेश हटाएं?';

  @override
  String chatScreenDeleteMessagesConfirm(int count) {
    return '$count संदेश हटाएं?';
  }

  @override
  String chatScreenDeleteMessagesForMeConfirm(int count) {
    return 'मेरे लिए $count संदेश हटाएं?';
  }

  @override
  String get chatScreenDeleteForMe => 'मेरे लिए हटाएं';

  @override
  String get chatScreenDeleteForEveryone => 'सभी के लिए हटाएं';

  @override
  String chatScreenDeleteFailed(String error) {
    return 'हटाने में विफल: $error';
  }

  @override
  String chatScreenCallStartFailed(String error) {
    return 'कॉल शुरू करने में विफल: $error';
  }

  @override
  String get chatScreenMicPermissionDenied =>
      'माइक्रोफ़ोन की अनुमति नहीं दी गई';

  @override
  String get chatScreenCallWhileRecording =>
      'कॉल शुरू करने से पहले वॉइस रिकॉर्डिंग बंद करें';

  @override
  String get chatScreenRecordWhileInCall => 'आप पहले से ही कॉल पर हैं';

  @override
  String get chatScreenRecordingStoppedForCall =>
      'कॉल के लिए वॉइस रिकॉर्डिंग रोक दी गई';

  @override
  String get chatHeaderOnline => 'ऑनलाइन';

  @override
  String chatHeaderLastSeenToday(String time) {
    return 'आज $time बजे देखा गया';
  }

  @override
  String chatHeaderLastSeenYesterday(String time) {
    return 'कल $time बजे देखा गया';
  }

  @override
  String chatHeaderLastSeenOn(String date, String time) {
    return '$date को $time बजे देखा गया';
  }

  @override
  String get chatScreenMessageTooShort => 'संदेश बहुत छोटा है';

  @override
  String chatScreenVoiceSendFailed(String error) {
    return 'वॉइस संदेश भेजने में विफल: $error';
  }

  @override
  String get chatScreenReply => 'जवाब दें';

  @override
  String get chatScreenForward => 'फ़ॉरवर्ड करें';

  @override
  String get chatScreenCopy => 'कॉपी करें';

  @override
  String get chatScreenPin => 'पिन करें';

  @override
  String get chatScreenUnpin => 'अनपिन करें';

  @override
  String get chatScreenTranslate => 'अनुवाद करें';

  @override
  String get chatScreenShowOriginal => 'मूल दिखाएं';

  @override
  String get chatScreenTranslating => 'अनुवाद हो रहा है…';

  @override
  String get chatScreenTranslated => 'अनुवादित';

  @override
  String get chatScreenTranslateFailed =>
      'यह संदेश अनुवादित नहीं हो सका। अपना कनेक्शन जांचें और फिर से प्रयास करें।';

  @override
  String get chatScreenDeleteUnsend => 'हटाएं / भेजना पूर्ववत करें';

  @override
  String get chatScreenCopiedToClipboard => 'क्लिपबोर्ड पर कॉपी किया गया';

  @override
  String chatScreenForwardedTo(String name) {
    return '$name को फ़ॉरवर्ड किया गया';
  }

  @override
  String get chatScreenUploadingDocument => 'दस्तावेज़ अपलोड हो रहा है...';

  @override
  String chatScreenDocumentUploadFailed(String error) {
    return 'दस्तावेज़ अपलोड विफल: $error';
  }

  @override
  String get chatScreenContactsPermissionRequired =>
      'संपर्क साझा करने के लिए संपर्क अनुमति आवश्यक है।';

  @override
  String chatScreenShareContactFailed(String error) {
    return 'संपर्क साझा नहीं किया जा सका: $error';
  }

  @override
  String get chatScreenLocationPermissionRequired =>
      'अपना स्थान साझा करने के लिए स्थान अनुमति आवश्यक है।';

  @override
  String get chatScreenTurnOnLocationServices =>
      'अपना स्थान साझा करने के लिए लोकेशन सेवाएं चालू करें।';

  @override
  String get chatScreenGettingLocation =>
      'आपका स्थान प्राप्त किया जा रहा है...';

  @override
  String chatScreenShareLocationFailed(String error) {
    return 'स्थान साझा नहीं किया जा सका: $error';
  }

  @override
  String chatScreenSendingItems(int count) {
    return '$count आइटम भेजे जा रहे हैं...';
  }

  @override
  String chatScreenMediaUploadFailed(String error) {
    return 'मीडिया अपलोड करने में विफल: $error';
  }

  @override
  String get chatScreenUploadingVideo => 'वीडियो अपलोड हो रहा है...';

  @override
  String chatScreenVideoUploadFailed(String error) {
    return 'वीडियो अपलोड विफल: $error';
  }

  @override
  String chatScreenUploadFailed(String error) {
    return 'अपलोड विफल: $error';
  }

  @override
  String chatScreenSelectedCount(int count) {
    return '$count चयनित';
  }

  @override
  String get chatScreenVideoCall => 'वीडियो कॉल';

  @override
  String get chatScreenVoiceCall => 'वॉइस कॉल';

  @override
  String get chatScreenOriginalMessageSender => 'मूल संदेश';

  @override
  String get chatScreenOriginalMessageNotFound =>
      'मूल संदेश इतिहास में नहीं मिला';

  @override
  String get homeScreenTitle => 'चैट्स';

  @override
  String get homeScreenArchived => 'संग्रहीत';

  @override
  String get homeScreenMyStory => 'मेरी स्टोरी';

  @override
  String get homeScreenFilterAll => 'सभी';

  @override
  String get homeScreenFilterUnread => 'अपठित';

  @override
  String get homeScreenFilterGroups => 'ग्रुप्स';

  @override
  String get homeScreenFilterChannels => 'चैनल्स';

  @override
  String get homeScreenFilterBots => 'बॉट्स';

  @override
  String get homeScreenPinChat => 'चैट पिन करें';

  @override
  String get homeScreenUnpinChat => 'पिन हटाएं';

  @override
  String get homeScreenMuteNotifications => 'सूचनाएं म्यूट करें';

  @override
  String get homeScreenArchiveChat => 'चैट संग्रहीत करें';

  @override
  String get homeScreenUnarchiveChat => 'संग्रह से हटाएं';

  @override
  String get homeScreenLeaveGroup => 'ग्रुप छोड़ें';

  @override
  String get homeScreenBlockContact => 'संपर्क ब्लॉक करें';

  @override
  String get homeScreenUnblockContact => 'अनब्लॉक करें';

  @override
  String get homeScreenDeleteChat => 'चैट हटाएं';

  @override
  String get homeScreenContactNotIdentified => 'इस संपर्क की पहचान नहीं हो सकी';

  @override
  String homeScreenBlockConfirmTitle(String name) {
    return '$name को ब्लॉक करें?';
  }

  @override
  String get homeScreenBlockConfirmBody =>
      'वे अब आपको मैसेज या कॉल नहीं कर पाएंगे, और आप भी उन्हें मैसेज या कॉल नहीं कर पाएंगे।';

  @override
  String homeScreenContactBlocked(String name) {
    return '$name को ब्लॉक कर दिया गया';
  }

  @override
  String homeScreenContactUnblocked(String name) {
    return '$name को अनब्लॉक कर दिया गया';
  }

  @override
  String homeScreenBlockStatusUpdateFailed(String error) {
    return 'ब्लॉक स्थिति अपडेट करने में विफल: $error';
  }

  @override
  String homeScreenDeleteChatBody(String name) {
    return 'क्या आप $name के साथ अपनी चैट हटाना चाहते हैं? नया मैसेज आने पर यह फिर से दिखाई देगी।';
  }

  @override
  String homeScreenLeaveGroupBody(String name) {
    return 'क्या आप वाकई \"$name\" छोड़ना चाहते हैं?';
  }

  @override
  String get homeScreenLeaveGroupFailed => 'ग्रुप छोड़ने में विफल';

  @override
  String get homeScreenNoChatsFound => 'कोई चैट नहीं मिली';

  @override
  String get homeScreenNoChatsYet => 'अभी तक कोई चैट नहीं';

  @override
  String homeScreenNoConversationsMatch(String query) {
    return '“$query” से मेल खाने वाली कोई बातचीत नहीं मिली।';
  }

  @override
  String get homeScreenEmptyStateHint =>
      'यहां देखने के लिए कोई बातचीत शुरू करें या ग्रुप बनाएं।';

  @override
  String get homeScreenSearchPeople => 'लोगों को खोजें';

  @override
  String get createGroupScreenTitle => 'ग्रुप बनाएं';

  @override
  String get createGroupScreenNext => 'आगे';

  @override
  String get createGroupScreenNameLabel => 'ग्रुप का नाम';

  @override
  String get createGroupScreenNameHint => 'ग्रुप का नाम दर्ज करें';

  @override
  String get createGroupScreenDescriptionLabel => 'ग्रुप का विवरण';

  @override
  String get createGroupScreenOptional => '(वैकल्पिक)';

  @override
  String get createGroupScreenDescriptionHint =>
      'लोगों को बताएं कि यह ग्रुप किस बारे में है...';

  @override
  String get createGroupScreenDescriptionHelper =>
      'आप बाद में विवरण जोड़ सकते हैं';

  @override
  String get createGroupScreenUploadingPhoto => 'अपलोड हो रहा है…';

  @override
  String get createGroupScreenAddPhoto => 'ग्रुप फ़ोटो जोड़ें';

  @override
  String get createGroupScreenChangePhoto => 'ग्रुप फ़ोटो बदलें';

  @override
  String createGroupScreenPhotoUploadFailed(String error) {
    return 'फ़ोटो अपलोड करने में विफल: $error';
  }

  @override
  String get createGroupScreenEnterName => 'कृपया ग्रुप का नाम दर्ज करें';

  @override
  String get createGroupScreenSelectAtLeastOneMember =>
      'कम से कम 1 सदस्य चुनें';

  @override
  String createGroupScreenCreateFailed(String error) {
    return 'ग्रुप बनाने में विफल: $error';
  }

  @override
  String get createGroupScreenSelectMembers => 'सदस्य चुनें';

  @override
  String get createGroupScreenSelectMembersSubtitle =>
      'जिन लोगों को आप इस ग्रुप में जोड़ना चाहते हैं उन्हें जोड़ें';

  @override
  String createGroupScreenSelectedCount(int count) {
    return '$count चयनित';
  }

  @override
  String get createGroupScreenSearchMembersHint =>
      'नाम, यूज़रनेम या Talkmos ID से खोजें';

  @override
  String get createGroupScreenNoContactsEmpty =>
      'अभी तक कोई संपर्क नहीं है। ग्रुप शुरू करने के लिए दोस्त जोड़ें।';

  @override
  String createGroupScreenNoContactsMatch(String query) {
    return '\"$query\" से मेल खाने वाला कोई संपर्क नहीं मिला।';
  }

  @override
  String createGroupScreenMemberCount(int count) {
    return '$count सदस्य';
  }

  @override
  String get archivedChatsScreenTitle => 'संग्रहीत';

  @override
  String get archivedChatsScreenUnarchiveChat => 'संग्रह से हटाएं';

  @override
  String get archivedChatsScreenMuteNotifications => 'सूचनाएं म्यूट करें';

  @override
  String get archivedChatsScreenLeaveGroup => 'ग्रुप छोड़ें';

  @override
  String get archivedChatsScreenDeleteChat => 'चैट हटाएं';

  @override
  String archivedChatsScreenDeleteChatBody(String name) {
    return 'क्या आप $name के साथ अपनी चैट हटाना चाहते हैं? नया मैसेज आने पर यह फिर से दिखाई देगी।';
  }

  @override
  String archivedChatsScreenLeaveGroupBody(String name) {
    return 'क्या आप वाकई \"$name\" छोड़ना चाहते हैं?';
  }

  @override
  String get archivedChatsScreenLeaveGroupFailed => 'ग्रुप छोड़ने में विफल';

  @override
  String get archivedChatsScreenEmptyTitle => 'कोई संग्रहीत चैट नहीं';

  @override
  String get archivedChatsScreenEmptyBody =>
      'जिन चैट्स को आप संग्रहीत करेंगे वे यहां दिखेंगी और आपकी मुख्य सूची से बाहर रहेंगी।';

  @override
  String get groupProfileScreenFailedToLoad => 'समूह विवरण लोड करने में विफल';

  @override
  String get groupProfileScreenImageUpdated =>
      'समूह की फ़ोटो सफलतापूर्वक अपडेट हो गई!';

  @override
  String groupProfileScreenUploadFailed(String error) {
    return 'समूह की फ़ोटो अपलोड करने में विफल: $error';
  }

  @override
  String get groupProfileScreenDescriptionUpdated =>
      'समूह का विवरण अपडेट हो गया';

  @override
  String get groupProfileScreenDescriptionUpdateFailed =>
      'विवरण अपडेट करने में विफल';

  @override
  String get groupProfileScreenNameUpdated => 'समूह का नाम अपडेट हो गया';

  @override
  String get groupProfileScreenNameUpdateFailed => 'नाम अपडेट करने में विफल';

  @override
  String get groupProfileScreenLeaveGroup => 'समूह छोड़ें';

  @override
  String get groupProfileScreenLeaveGroupConfirm =>
      'क्या आप वाकई इस समूह को छोड़ना चाहते हैं?';

  @override
  String get groupProfileScreenLeaveFailed => 'समूह छोड़ने में विफल';

  @override
  String get groupProfileScreenDeleteGroup => 'समूह हटाएं';

  @override
  String get groupProfileScreenDeleteGroupConfirm =>
      'इससे समूह सभी के लिए हट जाएगा, इसके मैसेज सहित। इसे वापस नहीं लाया जा सकता।';

  @override
  String get groupProfileScreenDeleteFailed => 'समूह हटाने में विफल';

  @override
  String get groupProfileScreenGroupDeleted => 'समूह हटा दिया गया';

  @override
  String get groupProfileScreenRemoveMemberTitle => 'सदस्य हटाएं';

  @override
  String groupProfileScreenRemoveMemberBody(String name) {
    return '$name को समूह से हटाएं?';
  }

  @override
  String groupProfileScreenMemberRemoved(String name) {
    return '$name हटा दिया गया';
  }

  @override
  String get groupProfileScreenRemoveMemberFailed => 'सदस्य हटाने में विफल';

  @override
  String get groupProfileScreenAddMembersTitle => 'सदस्य जोड़ें';

  @override
  String groupProfileScreenAddButtonLabel(int count) {
    return 'जोड़ें ($count)';
  }

  @override
  String groupProfileScreenMembersAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सदस्य जोड़े गए',
      one: '$count सदस्य जोड़ा गया',
    );
    return '$_temp0';
  }

  @override
  String groupProfileScreenAddMembersFailed(String error) {
    return 'सदस्य जोड़ने में विफल: $error';
  }

  @override
  String get groupProfileScreenNoMoreContacts =>
      'जोड़ने के लिए और कोई संपर्क नहीं है';

  @override
  String get groupProfileScreenTitle => 'समूह सेटिंग्स';

  @override
  String get groupProfileScreenInviteMembers => 'सदस्यों को आमंत्रित करें';

  @override
  String get groupProfileScreenPrivacy => 'गोपनीयता';

  @override
  String get groupProfileScreenEditGroupInfo => 'समूह की जानकारी संपादित करें';

  @override
  String get groupProfileScreenMediaVisibility => 'मीडिया दृश्यता';

  @override
  String get groupProfileScreenMuteNotifications => 'सूचनाएं म्यूट करें';

  @override
  String get groupProfileScreenDangerZone => 'जोखिम क्षेत्र';

  @override
  String groupProfileScreenMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सदस्य',
      one: '$count सदस्य',
    );
    return '$_temp0';
  }

  @override
  String groupProfileScreenMembersCountTitle(int count) {
    return 'सदस्य ($count)';
  }

  @override
  String get groupProfileScreenNoAdminsYet => 'अभी तक कोई एडमिन नहीं है।';

  @override
  String get groupProfileScreenNoMembersYet => 'अभी तक कोई सदस्य नहीं है।';

  @override
  String get groupProfileScreenOwnerRole => 'स्वामी';

  @override
  String get groupProfileScreenGroupNameLabel => 'समूह का नाम';

  @override
  String get groupProfileScreenDescriptionLabel => 'विवरण';

  @override
  String get mediaPreviewScreenAddTextLabelTitle => 'टेक्स्ट लेबल जोड़ें';

  @override
  String get mediaPreviewScreenTypeTextHint => 'यहां टेक्स्ट लिखें...';

  @override
  String mediaPreviewScreenFileSize(String size) {
    return '$size';
  }

  @override
  String get mediaPreviewScreenCropImageTooltip => 'छवि क्रॉप करें';

  @override
  String get mediaPreviewScreenRotateImageTooltip => 'छवि घुमाएं';

  @override
  String get mediaPreviewScreenAddTextTooltip => 'टेक्स्ट जोड़ें';

  @override
  String get mediaPreviewScreenDrawDoodleTooltip => 'डूडल बनाएं';

  @override
  String get mediaPreviewScreenUndoStrokeTooltip =>
      'पिछला स्ट्रोक पूर्ववत करें';

  @override
  String get mediaPreviewScreenCaptionHint => 'कैप्शन जोड़ें…';

  @override
  String get groupPermissionsScreenSendMessagesLabel => 'संदेश भेजें';

  @override
  String get groupPermissionsScreenSendMessagesDescription =>
      'इस समूह में कौन पोस्ट कर सकता है';

  @override
  String get groupPermissionsScreenEditInfoLabel =>
      'समूह की जानकारी संपादित करें';

  @override
  String get groupPermissionsScreenEditInfoDescription =>
      'नाम, फ़ोटो और विवरण कौन बदल सकता है';

  @override
  String get groupPermissionsScreenAddMembersLabel => 'सदस्य जोड़ें';

  @override
  String get groupPermissionsScreenAddMembersDescription =>
      'इस समूह में लोगों को कौन आमंत्रित कर सकता है';

  @override
  String get groupPermissionsScreenAdminOnlyNotice =>
      'केवल समूह के एडमिन ही इन सेटिंग्स को बदल सकते हैं।';

  @override
  String get groupPermissionsScreenAllMembers => 'सभी सदस्य';

  @override
  String get groupPermissionsScreenOnlyAdmins => 'केवल एडमिन';

  @override
  String groupPermissionsScreenUpdateFailed(String error) {
    return 'अपडेट नहीं हो सका: $error';
  }

  @override
  String get videoPlayerScreenLoadFailed => 'वीडियो लोड करने में विफल';

  @override
  String get sharedMediaScreenTitle => 'साझा मीडिया';

  @override
  String get sharedMediaScreenLoadFailed => 'साझा मीडिया लोड नहीं हो सका';

  @override
  String get sharedMediaScreenEmptyTitle =>
      'अभी तक कोई मीडिया साझा नहीं किया गया';

  @override
  String get sharedMediaScreenEmptyBody =>
      'आप जो फ़ोटो और वीडियो यहां भेजते या प्राप्त करते हैं\nवे इस गैलरी में दिखाई देंगे।';

  @override
  String get imageViewerLoadFailed => 'छवि लोड करने में विफल';

  @override
  String get chatBubbleEdited => 'संपादित';

  @override
  String get chatBubbleReadMore => 'और पढ़ें';

  @override
  String get chatBubbleReadLess => 'कम पढ़ें';

  @override
  String get chatInputBarEditMessage => 'मैसेज संपादित करें';

  @override
  String get chatInputBarHint => 'मैसेज लिखें…';

  @override
  String get chatHeaderTypingLabel => 'टाइप कर रहे हैं';

  @override
  String get contextActionMenuActionsLabel => 'कार्रवाइयाँ';

  @override
  String get chatBodyPrivacyBanner => 'मैसेज इस चैट के लिए निजी हैं।';

  @override
  String chatBodyYouBlocked(String peerName) {
    return 'आपने $peerName को ब्लॉक कर दिया है';
  }

  @override
  String get chatBodyNoMessagesYet => 'अभी तक कोई मैसेज नहीं';

  @override
  String chatBodySayHi(String name) {
    return 'बातचीत शुरू करने के लिए $name को नमस्ते कहें।';
  }

  @override
  String recentChatTileContactWithName(String name) {
    return 'संपर्क: $name';
  }

  @override
  String get recentChatTileContact => 'संपर्क';

  @override
  String get recentChatTileTapToOpen => 'बातचीत खोलने के लिए टैप करें';

  @override
  String get mediaVisibilityPermissionNeeded =>
      'आपकी गैलरी में जोड़ने के लिए Talkmos को अनुमति चाहिए। आप इसे सिस्टम सेटिंग्स में दे सकते हैं।';

  @override
  String get mediaVisibilitySheetTitle => 'मीडिया दृश्यता';

  @override
  String get mediaVisibilitySheetDescription =>
      'क्या इस चैट की फ़ोटो और वीडियो इस डिवाइस की गैलरी में सेव होंगी।';

  @override
  String get mediaVisibilitySheetFollowsGlobal =>
      'यह ग्लोबल \"फ़ोटो में सेव करें\" सेटिंग का पालन करता है';

  @override
  String get wallpaperPickerNone => 'कोई नहीं';

  @override
  String get attachmentSheetDocument => 'दस्तावेज़';

  @override
  String get attachmentSheetCamera => 'कैमरा';

  @override
  String get attachmentSheetContact => 'संपर्क';

  @override
  String get forwardMessageSheetTitle => 'इन्हें अग्रेषित करें';

  @override
  String get forwardMessageSheetNoChats => 'कोई चैट उपलब्ध नहीं है';

  @override
  String get pinnedMessageBannerTitle => 'पिन किया गया मैसेज';

  @override
  String get pinnedMessageBannerConfirmTitle => 'मैसेज अनपिन करें?';

  @override
  String get pinnedMessageBannerConfirmBody =>
      'क्या आप वाकई इस मैसेज को अनपिन करना चाहते हैं?';

  @override
  String get pinnedMessageBannerUnpinAction => 'अनपिन करें';

  @override
  String wizardStepHeaderStepOf(int current, int total) {
    return 'चरण $current में से $total';
  }

  @override
  String get deletedMessageBody => 'यह मैसेज डिलीट कर दिया गया है';

  @override
  String get voiceMessageFailedToPlay => 'ऑडियो चलाने में विफल';

  @override
  String get imageMessageFailedToLoad => 'इमेज लोड करने में विफल';

  @override
  String get locationMessageCurrentLocation => 'वर्तमान स्थान';

  @override
  String get documentMessageDefaultName => 'दस्तावेज़';

  @override
  String get documentMessageFileExtensionFallback => 'फ़ाइल';

  @override
  String documentMessageOpenFailed(String reason) {
    return 'फ़ाइल खोली नहीं जा सकी: $reason';
  }

  @override
  String get documentMessageDownloadFailed => 'फ़ाइल डाउनलोड नहीं हो सकी';

  @override
  String get documentMessagePageCountOne => '1 पृष्ठ';

  @override
  String documentMessagePageCount(int count) {
    return '$count पृष्ठ';
  }

  @override
  String get completeProfileScreenTitle => 'अपनी प्रोफ़ाइल पूरी करें';

  @override
  String get completeProfileScreenSubtitle =>
      'हमें बताएं कि आप कौन हैं ताकि दोस्त आपको खोज सकें।';

  @override
  String get completeProfileScreenFullName => 'पूरा नाम';

  @override
  String get completeProfileScreenFullNameHint => 'जैसे Alex Morgan';

  @override
  String get completeProfileScreenNameRequired => 'कृपया अपना नाम दर्ज करें';

  @override
  String get completeProfileScreenUsernameHint => 'जैसे alexmorgan';

  @override
  String get completeProfileScreenUsernameMinLength =>
      'कम से कम 3 अक्षर होने चाहिए';

  @override
  String get completeProfileScreenFinish => 'पूर्ण करें';

  @override
  String get phoneLoginScreenSelectCountryCode => 'देश कोड चुनें';

  @override
  String get phoneLoginScreenInvalidPhone =>
      'कृपया मान्य 10 अंकों का फ़ोन नंबर दर्ज करें';

  @override
  String get phoneLoginScreenSubtitle =>
      'चैट शुरू करने के लिए लॉगिन या रजिस्टर करें';

  @override
  String get phoneLoginScreenPhoneNumberLabel => 'फ़ोन नंबर';

  @override
  String get phoneLoginScreenContinueWithApple => 'Apple के साथ जारी रखें';

  @override
  String get phoneLoginScreenAppleComingSoon => 'Apple साइन-इन जल्द आ रहा है';

  @override
  String get phoneLoginScreenContinueWithGoogle => 'Google के साथ जारी रखें';

  @override
  String get phoneLoginScreenPhoneHint => 'फ़ोन नंबर दर्ज करें';

  @override
  String get phoneLoginScreenContinue => 'जारी रखें';

  @override
  String get phoneLoginScreenVerificationNote =>
      'हम आपके नंबर की पुष्टि के लिए\nएक सत्यापन कोड भेजेंगे';

  @override
  String get phoneLoginScreenOr => 'या';

  @override
  String get phoneLoginScreenAgreeTerms => 'जारी रखकर, आप हमारी';

  @override
  String get phoneLoginScreenTermsOfService => 'सेवा की शर्तों';

  @override
  String get phoneLoginScreenAnd => ' और ';

  @override
  String get phoneLoginScreenPrivacyPolicy => 'गोपनीयता नीति';

  @override
  String get phoneConfirmationScreenSelectCountryCode => 'देश कोड चुनें';

  @override
  String get phoneConfirmationScreenInvalidPhone =>
      'कृपया मान्य 10 अंकों का फ़ोन नंबर दर्ज करें';

  @override
  String get phoneConfirmationScreenPhoneHint => 'फ़ोन नंबर दर्ज करें';

  @override
  String get phoneConfirmationScreenTitle => 'अपना फ़ोन नंबर पुष्टि करें';

  @override
  String get phoneConfirmationScreenSubtitle =>
      'अपने खाते को सुरक्षित रखने और अपने संपर्कों से जुड़ने के लिए, कृपया अपना मोबाइल नंबर दर्ज करें।';

  @override
  String get phoneConfirmationScreenConfirmContinue =>
      'पुष्टि करें और जारी रखें';

  @override
  String get otpVerificationScreenEnterCode => 'सत्यापन कोड दर्ज करें';

  @override
  String get otpVerificationScreenCodeResent =>
      'कोड सफलतापूर्वक फिर से भेजा गया';

  @override
  String get otpVerificationScreenReceivedOtp => 'बैकएंड से OTP प्राप्त हुआ';

  @override
  String get otpVerificationScreenOtpFilled =>
      'OTP टेक्स्ट फ़ील्ड में भर दिया गया';

  @override
  String get otpVerificationScreenDirectOtpNote =>
      'सर्वर से सीधा OTP • फिर से भरने के लिए कोड पर टैप करें';

  @override
  String get otpVerificationScreenTitle => 'अपना नंबर सत्यापित करें';

  @override
  String otpVerificationScreenSentTo(String phone) {
    return '$phone पर भेजे गए 6 अंकों के कोड को दर्ज करें';
  }

  @override
  String get otpVerificationScreenVerify => 'सत्यापित करें';

  @override
  String get otpVerificationScreenDidntGetCode => 'कोड नहीं मिला? ';

  @override
  String get otpVerificationScreenSending => 'भेजा जा रहा है…';

  @override
  String get otpVerificationScreenResend => 'फिर से भेजें';

  @override
  String get registerScreenAccountCreated => 'खाता सफलतापूर्वक बन गया!';

  @override
  String get registerScreenCreateYourPrefix => 'अपना ';

  @override
  String get registerScreenAccountWord => 'खाता बनाएं';

  @override
  String get registerScreenSubtitle =>
      'Talkmos से जुड़ें और अपनी टीम व समुदाय से जुड़ना शुरू करें।';

  @override
  String get registerScreenFullName => 'पूरा नाम';

  @override
  String get registerScreenFullNameHint => 'अपना पूरा नाम दर्ज करें';

  @override
  String get registerScreenNameRequired => 'नाम आवश्यक है';

  @override
  String get registerScreenEmailAddress => 'ईमेल पता';

  @override
  String get registerScreenEmailHint => 'अपना ईमेल पता दर्ज करें';

  @override
  String get registerScreenEmailRequired => 'ईमेल आवश्यक है';

  @override
  String get registerScreenEmailInvalid => 'मान्य ईमेल पता दर्ज करें';

  @override
  String get registerScreenPasswordHint => 'पासवर्ड दर्ज करें';

  @override
  String get registerScreenPasswordRequired => 'पासवर्ड आवश्यक है';

  @override
  String get registerScreenPasswordMinLength =>
      'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए';

  @override
  String get registerScreenConfirmPassword => 'पासवर्ड की पुष्टि करें';

  @override
  String get registerScreenConfirmPasswordHint => 'पासवर्ड की पुष्टि करें';

  @override
  String get registerScreenConfirmPasswordRequired =>
      'पासवर्ड की पुष्टि आवश्यक है';

  @override
  String get registerScreenPasswordsMismatch => 'पासवर्ड मेल नहीं खाते';

  @override
  String get registerScreenSignUp => 'साइन अप करें';

  @override
  String get registerScreenOrContinueWith => 'या इसके साथ जारी रखें';

  @override
  String get registerScreenSignInWithGoogle => 'Google से साइन इन करें';

  @override
  String get registerScreenAlreadyHaveAccount => 'पहले से खाता है? ';

  @override
  String get registerScreenSignIn => 'साइन इन करें';

  @override
  String get loginScreenWelcomeBackTo => 'पर आपका फिर से स्वागत है ';

  @override
  String get loginScreenSubtitle =>
      'अपनी टीम से जुड़ने और अपने समुदाय तक पहुंचने के लिए लॉग इन करें।';

  @override
  String get loginScreenPhoneOrUsername => 'फ़ोन या यूज़रनेम';

  @override
  String get loginScreenPhoneOrUsernameHint => '+1234567890 या यूज़रनेम';

  @override
  String get loginScreenPhoneOrUsernameRequired => 'फ़ोन या यूज़रनेम आवश्यक है';

  @override
  String get loginScreenPasswordHint => 'पासवर्ड दर्ज करें';

  @override
  String get loginScreenPasswordRequired => 'पासवर्ड आवश्यक है';

  @override
  String get loginScreenForgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get loginScreenSignIn => 'साइन इन करें';

  @override
  String get loginScreenOrContinueWith => 'या इसके साथ जारी रखें';

  @override
  String get loginScreenSignInWithGoogle => 'Google से साइन इन करें';

  @override
  String get loginScreenSignInWithPhoneOtp => 'फ़ोन OTP से साइन इन करें';

  @override
  String get loginScreenDontHaveAccount => 'खाता नहीं है? ';

  @override
  String get loginScreenSignUp => 'साइन अप करें';

  @override
  String get welcomeScreenTagline => 'चैट करें। मिलें। सहयोग करें।';

  @override
  String get welcomeScreenDescription =>
      'चैट, कॉल, स्मार्ट मीटिंग और समुदायों के लिए ऑल-इन-वन कम्युनिकेशन प्लेटफ़ॉर्म।';

  @override
  String get welcomeScreenLetsStart => 'शुरू करें';

  @override
  String get forgotPasswordScreenEmailRequired =>
      'कृपया अपना ईमेल या फ़ोन नंबर दर्ज करें।';

  @override
  String get forgotPasswordScreenCodeResent => 'एक नया कोड भेजा गया है।';

  @override
  String get forgotPasswordScreenIncompleteCode =>
      'कृपया पूरा 6 अंकों का कोड दर्ज करें।';

  @override
  String get forgotPasswordScreenPasswordMinLength =>
      'पासवर्ड कम से कम 8 अक्षरों का होना चाहिए।';

  @override
  String get forgotPasswordScreenPasswordsMismatch => 'पासवर्ड मेल नहीं खाते।';

  @override
  String get forgotPasswordScreenTitleEmail => 'पासवर्ड भूल गए';

  @override
  String get forgotPasswordScreenTitleOtp => 'सत्यापन कोड दर्ज करें';

  @override
  String get forgotPasswordScreenTitleNewPassword => 'नया पासवर्ड सेट करें';

  @override
  String get forgotPasswordScreenSubtitleEmail =>
      'अपना ईमेल या फ़ोन दर्ज करें, हम आपको एक सत्यापन कोड भेजेंगे।';

  @override
  String get forgotPasswordScreenSubtitleOtp =>
      'हमने जो 6 अंकों का कोड भेजा है, उसके लिए अपना इनबॉक्स या मैसेज देखें।';

  @override
  String get forgotPasswordScreenSubtitleNewPassword =>
      'एक मजबूत पासवर्ड चुनें जिसे आपने पहले इस्तेमाल नहीं किया हो।';

  @override
  String get forgotPasswordScreenEmailOrPhoneLabel => 'ईमेल या फ़ोन नंबर';

  @override
  String get forgotPasswordScreenEmailOrPhoneHint =>
      'name@example.com या +91...';

  @override
  String get forgotPasswordScreenSendCode => 'कोड भेजें';

  @override
  String forgotPasswordScreenCodeSentTo(String email) {
    return '$email पर कोड भेजा गया';
  }

  @override
  String get forgotPasswordScreenVerifyCode => 'कोड सत्यापित करें';

  @override
  String get forgotPasswordScreenDidntReceiveCode => 'कोड नहीं मिला? ';

  @override
  String get forgotPasswordScreenResend => 'फिर से भेजें';

  @override
  String get forgotPasswordScreenNewPasswordLabel => 'नया पासवर्ड';

  @override
  String get forgotPasswordScreenAtLeast8Chars => 'कम से कम 8 अक्षर';

  @override
  String get forgotPasswordScreenConfirmPasswordLabel =>
      'पासवर्ड की पुष्टि करें';

  @override
  String get forgotPasswordScreenReenterPassword =>
      'अपना पासवर्ड फिर से दर्ज करें';

  @override
  String get forgotPasswordScreenResetPassword => 'पासवर्ड रीसेट करें';

  @override
  String get forgotPasswordScreenChars8Plus => '8+ अक्षर';

  @override
  String get forgotPasswordScreenUppercase => 'अपरकेस';

  @override
  String get forgotPasswordScreenNumber => 'अंक';

  @override
  String get forgotPasswordScreenSuccessTitle => 'पासवर्ड रीसेट हो गया!';

  @override
  String get forgotPasswordScreenSuccessMessage =>
      'आपका पासवर्ड सफलतापूर्वक अपडेट हो गया है।\nअब आप अपने नए पासवर्ड से लॉग इन कर सकते हैं।';

  @override
  String get forgotPasswordScreenBackToLogin => 'लॉगिन पर वापस जाएं';

  @override
  String get editProfileScreenUpdateSuccess =>
      'प्रोफ़ाइल सफलतापूर्वक अपडेट हो गई!';

  @override
  String editProfileScreenUploadPhotoFailed(String error) {
    return 'फ़ोटो अपलोड नहीं हो सकी: $error';
  }

  @override
  String get editProfileScreenChangePhotoTitle => 'प्रोफ़ाइल फ़ोटो बदलें';

  @override
  String get editProfileScreenChoosePhotoSubtitle => 'अपने लिए एक फ़ोटो चुनें';

  @override
  String get editProfileScreenCameraLabel => 'कैमरा';

  @override
  String get editProfileScreenTakePhotoSubtitle => 'फ़ोटो लें';

  @override
  String get editProfileScreenPickFromLibrarySubtitle => 'लाइब्रेरी से चुनें';

  @override
  String get editProfileScreenRemoveCurrentPhoto => 'मौजूदा फ़ोटो हटाएं';

  @override
  String get editProfileScreenTitle => 'प्रोफ़ाइल संपादित करें';

  @override
  String get editProfileScreenBasicInfo => 'मूल जानकारी';

  @override
  String get editProfileScreenFullName => 'पूरा नाम';

  @override
  String get editProfileScreenFullNameHint => 'आपका प्रदर्शित नाम';

  @override
  String get editProfileScreenNameEmptyError => 'नाम खाली नहीं हो सकता';

  @override
  String get editProfileScreenUsernameHint =>
      'एक विशिष्ट हैंडल जिससे दूसरे आपको ढूंढ सकें';

  @override
  String get editProfileScreenBio => 'बायो';

  @override
  String get editProfileScreenBioHint => 'अपने बारे में एक छोटी सी बात';

  @override
  String get editProfileScreenLocationHint => 'आप कहाँ हैं';

  @override
  String get editProfileScreenEmail => 'ईमेल';

  @override
  String get editProfileScreenPhone => 'फ़ोन';

  @override
  String get editProfileScreenEmailPhoneNotice =>
      'ईमेल और फ़ोन आपके साइन-इन से जुड़े हैं और यहाँ संपादित नहीं किए जा सकते।';

  @override
  String get editProfileScreenSaveChanges => 'परिवर्तन सहेजें';

  @override
  String get editProfileScreenUploading => 'अपलोड हो रहा है…';

  @override
  String get editProfileScreenChangePhoto => 'फ़ोटो बदलें';

  @override
  String get appearanceSettingsScreenTitle => 'दिखावट';

  @override
  String get appearanceSettingsScreenInterfaceTheme => 'इंटरफ़ेस थीम';

  @override
  String get appearanceSettingsScreenBrandPrimaryColor => 'ब्रांड प्राथमिक रंग';

  @override
  String get appearanceSettingsScreenBrandColorDesc =>
      'ऐप में हाइलाइट और एक्शन बटन का रंग बदलता है।';

  @override
  String get appearanceSettingsScreenChatWallpaperStyle =>
      'चैट वॉलपेपर और स्टाइल';

  @override
  String get appearanceSettingsScreenColorBackdrop => 'रंगीन बैकड्रॉप';

  @override
  String get appearanceSettingsScreenBackgroundDoodles => 'बैकग्राउंड डूडल';

  @override
  String get appearanceSettingsScreenBackgroundDoodlesDesc =>
      'फ्लैट रंगों में हल्के चित्र जोड़ें।';

  @override
  String get appearanceSettingsScreenWallpaperGallery => 'वॉलपेपर गैलरी';

  @override
  String get appearanceSettingsScreenThemeLight => 'लाइट';

  @override
  String get appearanceSettingsScreenThemeDark => 'डार्क';

  @override
  String get appearanceSettingsScreenThemeSystem => 'सिस्टम';

  @override
  String get appearanceSettingsScreenImageOpacity => 'छवि की पारदर्शिता';

  @override
  String get privacySettingsScreenTitle => 'गोपनीयता और सुरक्षा';

  @override
  String get privacySettingsScreenPrivateAccountTitle => 'निजी अकाउंट';

  @override
  String get privacySettingsScreenPrivateAccountDescPrivate =>
      'आपका अकाउंट निजी है। जो लोग आपके संपर्क नहीं हैं, उन्हें आपको मैसेज करने, कॉल करने या आपकी स्टोरी देखने से पहले फ्रेंड रिक्वेस्ट भेजनी होगी।';

  @override
  String get privacySettingsScreenPrivateAccountDescPublic =>
      'आपका अकाउंट सार्वजनिक है। Talkmos पर कोई भी आपको मैसेज कर सकता है, कॉल कर सकता है और आपकी स्टोरी देख सकता है।';

  @override
  String get privacySettingsScreenPrivacyControls => 'गोपनीयता नियंत्रण';

  @override
  String get privacySettingsScreenReadReceipts => 'पढ़ी गई रसीदें';

  @override
  String get privacySettingsScreenReadReceiptsDesc =>
      'दूसरों को बताएं जब आपने उनके मैसेज पढ़ लिए हों।';

  @override
  String get privacySettingsScreenLastSeenOnline =>
      'अंतिम बार देखा गया और ऑनलाइन';

  @override
  String get privacySettingsScreenLastSeenSheetTitle =>
      'मुझे अंतिम बार कब देखा गया, यह कौन देख सकता है';

  @override
  String get privacySettingsScreenProfilePhotoTitle => 'प्रोफ़ाइल फ़ोटो';

  @override
  String get privacySettingsScreenProfilePhotoSheetTitle =>
      'मेरी प्रोफ़ाइल फ़ोटो कौन देख सकता है';

  @override
  String get privacySettingsScreenMedia => 'मीडिया';

  @override
  String get privacySettingsScreenSaveToPhotos => 'फ़ोटो में सेव करें';

  @override
  String get privacySettingsScreenSaveToPhotosDesc =>
      'आपको प्राप्त फ़ोटो और वीडियो इस डिवाइस की गैलरी में सेव करें, जहाँ अन्य ऐप्स उन्हें देख सकते हैं। डिफ़ॉल्ट रूप से बंद। अलग-अलग चैट इसे बदल सकती हैं।';

  @override
  String get privacySettingsScreenBlockedContacts => 'ब्लॉक किए गए संपर्क';

  @override
  String get privacySettingsScreenBlockedCountNone => 'कोई नहीं';

  @override
  String privacySettingsScreenBlockedCount(int count) {
    return '$count ब्लॉक किए गए';
  }

  @override
  String get privacySettingsScreenLegalPolicy => 'कानूनी और नीति';

  @override
  String get privacySettingsScreenPrivacyPolicy => 'गोपनीयता नीति';

  @override
  String get privacySettingsScreenPrivacyPolicyDesc =>
      'आपका डेटा कैसे संभाला जाता है';

  @override
  String get privacySettingsScreenTermsOfService => 'सेवा की शर्तें';

  @override
  String get privacySettingsScreenTermsDesc =>
      'साइन-अप के समय स्वीकार किया गया समझौता';

  @override
  String get privacySettingsScreenGalleryPermissionNeeded =>
      'Talkmos को आपकी गैलरी में जोड़ने के लिए अनुमति चाहिए। आप इसे सिस्टम सेटिंग्स में दे सकते हैं।';

  @override
  String get privacySettingsScreenSyncError =>
      'वह सेटिंग सेव नहीं हो सकी। अपना कनेक्शन जांचें।';

  @override
  String get privacySettingsScreenBrowserOpenError => 'ब्राउज़र नहीं खुल सका।';

  @override
  String get privacySettingsScreenConnectionSecured =>
      'आपका कनेक्शन सुरक्षित है';

  @override
  String get privacySettingsScreenConnectionSecuredDesc =>
      'मैसेज और कॉल एक एन्क्रिप्टेड कनेक्शन से भेजे जाते हैं, और केवल चैट में शामिल लोग ही उसे खोल सकते हैं। इस डिवाइस पर कैश किए गए मैसेज आराम की स्थिति में एन्क्रिप्टेड होते हैं।';

  @override
  String get profileScreenCheckingForUpdates => 'ऐप अपडेट की जांच हो रही है...';

  @override
  String profileScreenLatestVersion(String appName) {
    return 'आप $appName के नवीनतम संस्करण पर हैं!';
  }

  @override
  String profileScreenComingSoon(String feature) {
    return '$feature जल्द आ रहा है!';
  }

  @override
  String get profileScreenPrivacySecurity => 'गोपनीयता और सुरक्षा';

  @override
  String get profileScreenDataAndStorage => 'डेटा और स्टोरेज';

  @override
  String get profileScreenChatSettings => 'चैट सेटिंग्स';

  @override
  String get profileScreenLanguage => 'भाषा';

  @override
  String get profileScreenHelpSupport => 'सहायता और समर्थन';

  @override
  String get profileScreenCheckForUpdates => 'अपडेट जांचें';

  @override
  String get profileScreenLogOut => 'लॉग आउट';

  @override
  String get profileScreenUserFallback => 'उपयोगकर्ता';

  @override
  String get profileScreenAccountDesc => 'अपनी प्रोफ़ाइल जानकारी प्रबंधित करें';

  @override
  String get profileScreenPrivacySecurityDesc =>
      'नियंत्रित करें कि आपकी जानकारी कौन देख सकता है';

  @override
  String get profileScreenNotificationsDesc => 'मैसेज, ग्रुप और कॉल अलर्ट';

  @override
  String get profileScreenDataAndStorageDesc =>
      'स्टोरेज और मीडिया उपयोग प्रबंधित करें';

  @override
  String get profileScreenChatSettingsDesc => 'वॉलपेपर, थीम और चैट दिखावट';

  @override
  String get profileScreenDevicesDesc => 'प्रबंधित करें कि आप कहाँ लॉग इन हैं';

  @override
  String get profileScreenLanguageDesc => 'ऐप की भाषा बदलें';

  @override
  String get profileScreenCheckForUpdatesDesc =>
      'जांचें कि क्या कोई नया वर्शन उपलब्ध है';

  @override
  String get profileScreenAboutDesc => 'ऐप जानकारी और कानूनी विवरण';

  @override
  String get aboutScreenTitle => 'ऐप के बारे में';

  @override
  String aboutScreenVersion(String version) {
    return 'संस्करण $version';
  }

  @override
  String get aboutScreenLegalSectionTitle => 'कानूनी';

  @override
  String get aboutScreenTermsOfService => 'सेवा की शर्तें';

  @override
  String get aboutScreenPrivacyPolicy => 'गोपनीयता नीति';

  @override
  String get aboutScreenHelpSupportDesc => 'मदद पाएं या हमसे संपर्क करें';

  @override
  String get aboutScreenBrowserOpenError =>
      'ब्राउज़र खोलने में विफल। कृपया पुनः प्रयास करें।';

  @override
  String aboutScreenCopyright(String year, String appName) {
    return '© $year $appName. सर्वाधिकार सुरक्षित।';
  }

  @override
  String get dataStorageSettingsScreenTitle => 'डेटा और स्टोरेज';

  @override
  String get dataStorageSettingsScreenStorageHeader => 'स्टोरेज';

  @override
  String get dataStorageSettingsScreenCachedMedia => 'कैश्ड मीडिया';

  @override
  String get dataStorageSettingsScreenClearing => 'साफ़ हो रहा है…';

  @override
  String get dataStorageSettingsScreenTapToClear => 'साफ़ करने के लिए टैप करें';

  @override
  String get dataStorageSettingsScreenMeasuring => 'माप रहा है…';

  @override
  String get dataStorageSettingsScreenClearingSafeTitle =>
      'साफ़ करना सुरक्षित है';

  @override
  String get dataStorageSettingsScreenClearingSafeDesc =>
      'फ़ोटो, वीडियो और वॉइस नोट्स को दोबारा खोलने पर सर्वर से फिर से डाउनलोड किया जाता है। आपके मैसेज अलग से संग्रहीत हैं और इससे कभी नहीं हटाए जाते।';

  @override
  String get dataStorageSettingsScreenMediaUpload => 'मीडिया अपलोड';

  @override
  String get dataStorageSettingsScreenUploadQuality => 'अपलोड गुणवत्ता';

  @override
  String get dataStorageSettingsScreenAutomaticDownloads => 'स्वचालित डाउनलोड';

  @override
  String get dataStorageSettingsScreenAutoSaveWifiOnly =>
      'केवल Wi-Fi पर ऑटो-सेव करें';

  @override
  String get dataStorageSettingsScreenAutoSaveWifiOnlyDesc =>
      'प्राप्त मीडिया को अपनी गैलरी में सेव करने से पहले Wi-Fi का इंतज़ार करें। आप जो मीडिया खोलते हैं वह हमेशा किसी भी कनेक्शन पर डाउनलोड होता है।';

  @override
  String get dataStorageSettingsScreenSaveToPhotos => 'फ़ोटो में सेव करें';

  @override
  String get dataStorageSettingsScreenOn => 'चालू';

  @override
  String get dataStorageSettingsScreenOff => 'बंद';

  @override
  String get dataStorageSettingsScreenNothingAutoSavedTitle =>
      'कुछ भी ऑटो-सेव नहीं हो रहा है';

  @override
  String get dataStorageSettingsScreenNothingAutoSavedDesc =>
      'फ़ोटो में सेव करना बंद है, इसलिए प्राप्त मीडिया Talkmos के अंदर ही रहता है और ऊपर की Wi-Fi सेटिंग का अभी कोई असर नहीं है। अलग-अलग चैट अपने जानकारी पेज से इसे चालू कर सकती हैं।';

  @override
  String get dataStorageSettingsScreenPhotoUploadQualityTitle =>
      'फ़ोटो अपलोड गुणवत्ता';

  @override
  String get dataStorageSettingsScreenRecommended => 'अनुशंसित';

  @override
  String get dataStorageSettingsScreenQualityDataSaverDesc =>
      'सबसे छोटी फ़ाइलें, सबसे कम विवरण';

  @override
  String get dataStorageSettingsScreenQualityStandardDesc =>
      'संतुलित — जो Talkmos हमेशा से भेजता आया है';

  @override
  String get dataStorageSettingsScreenQualityHighDesc =>
      'सबसे स्पष्ट विवरण, सबसे बड़ी फ़ाइलें';

  @override
  String get dataStorageSettingsScreenClearCacheTitle =>
      'कैश्ड मीडिया साफ़ करें?';

  @override
  String dataStorageSettingsScreenClearCacheDesc(String size) {
    return 'यह कैश्ड मीडिया द्वारा उपयोग की जा रही जगह$size खाली कर देता है। फ़ोटो, वीडियो और वॉइस नोट्स अगली बार खोलने पर फिर से डाउनलोड होंगे। आपके मैसेज प्रभावित नहीं होते।';
  }

  @override
  String get dataStorageSettingsScreenClear => 'साफ़ करें';

  @override
  String get dataStorageSettingsScreenCacheCleared =>
      'कैश्ड मीडिया साफ़ हो गया';

  @override
  String get helpSupportScreenFaq1Question =>
      'मैं बातचीत को कैसे पिन या अनपिन करूं?';

  @override
  String get helpSupportScreenFaq1Answer =>
      'होम स्क्रीन पर हाल की चैट सूची पर जाएं। किसी भी बातचीत कार्ड को लंबे समय तक दबाएं और पॉप-अप विकल्प शीट से \'बातचीत पिन करें\' या \'बातचीत अनपिन करें\' चुनें। पिन की गई चैट आपकी सूची के शीर्ष पर बनी रहती हैं।';

  @override
  String get helpSupportScreenFaq2Question =>
      'मैं ऑडियो वॉइस मैसेज कैसे रिकॉर्ड और भेजूं?';

  @override
  String get helpSupportScreenFaq2Answer =>
      'कोई भी चैट रूम खोलें। वॉइस नोट रिकॉर्ड करने के लिए मैसेज बार में माइक आइकन को दबाकर रखें। बार में रिकॉर्डिंग की अवधि और कैंसिल का विकल्प दिखेगा। छोड़ने/भेजने पर आप एक प्रीमियम प्रीव्यू पेज पर पहुंचेंगे जहां आप शेयर करने से पहले अपनी WAV रिकॉर्डिंग सुन सकते हैं।';

  @override
  String get helpSupportScreenFaq3Question =>
      'मैं चैट वॉलपेपर बैकग्राउंड कहाँ बदल सकता हूँ?';

  @override
  String get helpSupportScreenFaq3Answer =>
      'अपने प्रोफ़ाइल टैब पर जाएं, \'दिखावट\' पर टैप करें, और चैट वॉलपेपर कस्टमाइज़ पैनल खोलें। आप कस्टम सॉलिड बैकड्रॉप रंग चुन सकते हैं या बैकग्राउंड डूडल चालू/बंद कर सकते हैं।';

  @override
  String get helpSupportScreenFaq4Question =>
      'चैट रूम के अंदर मैसेज पिनिंग कैसे काम करता है?';

  @override
  String get helpSupportScreenFaq4Answer =>
      'किसी भी चैट थ्रेड के अंदर, विवरण देखने के लिए मैसेज बबल पर एक बार टैप करें और ऐपबार में पिन बटन दबाएं। पिन किए गए मैसेज चैट रूम के शीर्ष पर एक फ्लोटिंग बैनर में दिखाई देते हैं। इसे टैप करने पर आप सीधे उस मैसेज पर स्वतः स्क्रॉल हो जाते हैं।';

  @override
  String get helpSupportScreenTicketSubmittedTitle => 'टिकट जमा हो गया';

  @override
  String get helpSupportScreenTicketSubmittedBody =>
      'Talkmos सपोर्ट से संपर्क करने के लिए धन्यवाद। आपका मैसेज सफलतापूर्वक भेज दिया गया है। हमारी टीम आपकी रिपोर्ट की समीक्षा करेगी और जल्द ही जवाब देगी।';

  @override
  String get helpSupportScreenTitle => 'सहायता और समर्थन';

  @override
  String get helpSupportScreenFaqHeading => 'अक्सर पूछे जाने वाले सवाल';

  @override
  String get helpSupportScreenSubmitTicketHeading => 'एक सपोर्ट टिकट जमा करें';

  @override
  String get helpSupportScreenSubjectLabel => 'विषय';

  @override
  String get helpSupportScreenSubjectHint => 'जैसे, बग रिपोर्ट, ऑडियो त्रुटि';

  @override
  String get helpSupportScreenSubjectRequired => 'कृपया एक विषय दर्ज करें';

  @override
  String get helpSupportScreenDescriptionLabel => 'विवरण / संदेश';

  @override
  String get helpSupportScreenDescriptionHint =>
      'हमें बताएं कि हम आपकी कैसे मदद कर सकते हैं...';

  @override
  String get helpSupportScreenDescriptionRequired => 'कृपया अपना अनुरोध बताएं';

  @override
  String get helpSupportScreenSubmitButton => 'टिकट जमा करें';

  @override
  String get notificationsSettingsScreenAlertChannels => 'अलर्ट चैनल';

  @override
  String get notificationsSettingsScreenReceiveNotifications =>
      'सूचनाएं प्राप्त करें';

  @override
  String get notificationsSettingsScreenReceiveNotificationsDesc =>
      'मैसेज और अपडेट के लिए तुरंत अलर्ट पाएं।';

  @override
  String get notificationsSettingsScreenMessageSound => 'मैसेज ध्वनि';

  @override
  String get notificationsSettingsScreenVibrationAlerts => 'कंपन अलर्ट';

  @override
  String get notificationsSettingsScreenVibrationAlertsDesc =>
      'हर अलर्ट पर हैप्टिक फीडबैक।';

  @override
  String get notificationsSettingsScreenMessagePreviews => 'मैसेज पूर्वावलोकन';

  @override
  String get notificationsSettingsScreenMessagePreviewsDesc =>
      'लॉक स्क्रीन पर सामग्री दिखाएं।';

  @override
  String get notificationsSettingsScreenCallRingtone => 'कॉल रिंगटोन';

  @override
  String get notificationsSettingsScreenAudioToneNoticeTitle =>
      'ऑडियो टोन सूचना';

  @override
  String get notificationsSettingsScreenAudioToneNoticeDesc =>
      'रिंगटोन में बदलाव अगली आने वाली कॉल पर प्रभावी होंगे। कुछ टोन आपके डिवाइस के आधार पर अलग लग सकते हैं।';

  @override
  String get notificationsSettingsScreenPrivateByDefaultTitle =>
      'डिफ़ॉल्ट रूप से निजी';

  @override
  String get notificationsSettingsScreenPrivateByDefaultDesc =>
      'केवल चैट में शामिल लोग ही उसके मैसेज पढ़ सकते हैं।';

  @override
  String get blockedContactsScreenTitle => 'ब्लॉक किए गए संपर्क';

  @override
  String blockedContactsScreenUnblockConfirmTitle(String name) {
    return '$name को अनब्लॉक करें?';
  }

  @override
  String get blockedContactsScreenUnblockConfirmBody =>
      'आप फिर से एक-दूसरे को मैसेज और कॉल कर सकेंगे।';

  @override
  String blockedContactsScreenUnblockFailed(String error) {
    return 'अनब्लॉक नहीं हो सका: $error';
  }

  @override
  String get blockedContactsScreenEmptyTitle =>
      'कोई ब्लॉक किया गया संपर्क नहीं';

  @override
  String get blockedContactsScreenEmptyDesc =>
      'जिन लोगों को आप ब्लॉक करते हैं वे अब आपको मैसेज या कॉल नहीं कर पाएंगे।';

  @override
  String get selectContactScreenSearchHint =>
      'नाम, यूज़रनेम या फ़ोन नंबर खोजें...';

  @override
  String get selectContactScreenTitle => 'संपर्क चुनें';

  @override
  String get selectContactScreenLoadingContacts => 'संपर्क लोड हो रहे हैं...';

  @override
  String selectContactScreenContactCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count संपर्क',
      one: '$count संपर्क',
    );
    return '$_temp0';
  }

  @override
  String get selectContactScreenNewGroup => 'नया ग्रुप';

  @override
  String get selectContactScreenNewGroupSubtitle => 'एक नया ग्रुप चैट बनाएं';

  @override
  String get selectContactScreenNewContact => 'नया संपर्क';

  @override
  String get selectContactScreenNewContactSubtitle =>
      'किसी दोस्त को जोड़ें या यूज़र्स खोजें';

  @override
  String get selectContactScreenContactsOnTalkmos => 'Talkmos पर मौजूद संपर्क';

  @override
  String get selectContactScreenFindContactsOnTalkmos =>
      'Talkmos पर संपर्क खोजें';

  @override
  String get selectContactScreenPermissionDeniedMessage =>
      'संपर्कों की अनुमति बंद है, इसलिए हम यह नहीं दिखा सकते कि Talkmos पर आपके पहले से कौन-कौन जुड़े हैं।';

  @override
  String get selectContactScreenTryAgain => 'फिर से कोशिश करें';

  @override
  String get selectContactScreenNoMatchingContacts =>
      'कोई मिलता-जुलता संपर्क नहीं मिला';

  @override
  String get selectContactScreenNothingToShowYet =>
      'अभी दिखाने के लिए कुछ नहीं है';

  @override
  String selectContactScreenNoPhoneContactsMatch(String query) {
    return '\"$query\" से मेल खाने वाला कोई फ़ोन संपर्क नहीं मिला।';
  }

  @override
  String get selectContactScreenIndianNumbersOnly =>
      'हम केवल इस फ़ोन में सेव किए गए भारतीय मोबाइल नंबर ही दिखाते हैं। कोई संपर्क सेव करें, फिर उसे यहां देखने के लिए रीफ्रेश करें।';

  @override
  String get selectContactScreenClearSearch => 'खोज साफ़ करें';

  @override
  String get selectContactScreenRefreshContacts => 'संपर्क रीफ्रेश करें';

  @override
  String get selectContactScreenFromYourContacts => 'आपके संपर्कों में से';

  @override
  String get selectContactScreenInvite => 'आमंत्रित करें';

  @override
  String get selectContactScreenAddFriendTooltip => 'दोस्त जोड़ें';

  @override
  String get selectContactScreenRequested => 'अनुरोध भेजा गया';

  @override
  String get selectContactScreenWantsToConnect => 'जुड़ना चाहता है';

  @override
  String selectContactScreenCouldNotOpenChat(String error) {
    return 'चैट नहीं खोली जा सकी: $error';
  }

  @override
  String get selectContactScreenFriendRequestSent =>
      'दोस्ती का अनुरोध भेज दिया गया';

  @override
  String selectContactScreenCouldNotSendRequest(String error) {
    return 'अनुरोध नहीं भेजा जा सका: $error';
  }

  @override
  String get selectContactScreenInviteMessage =>
      'मेरे साथ Talkmos पर जुड़ें — https://talkmos.com';

  @override
  String get selectContactScreenNoMessagingApp =>
      'कोई मैसेजिंग ऐप उपलब्ध नहीं है';

  @override
  String get selectContactScreenCouldNotOpenMessagingApp =>
      'मैसेजिंग ऐप नहीं खोला जा सका';

  @override
  String get selectContactScreenDefaultStatus =>
      'नमस्ते! मैं Talkmos इस्तेमाल कर रहा/रही हूं';

  @override
  String get selectContactScreenNoContactsFound => 'कोई संपर्क नहीं मिला';

  @override
  String selectContactScreenNoFriendsFoundMatching(String query) {
    return '\"$query\" से मेल खाने वाला कोई दोस्त नहीं मिला।';
  }

  @override
  String get selectContactScreenAddFriendsToStartChatting =>
      'चैट शुरू करने के लिए दोस्त जोड़ें या Talkmos पर लोगों को खोजें।';

  @override
  String get selectContactScreenFindContacts => 'संपर्क खोजें';

  @override
  String get userProfileScreenStartConversationBeforeMedia =>
      'शेयर की गई मीडिया देखने से पहले बातचीत शुरू करें।';

  @override
  String get userProfileScreenStartConversationBeforeMuting =>
      'म्यूट करने से पहले बातचीत शुरू करें।';

  @override
  String get userProfileScreenStartConversationBeforeChanging =>
      'इसे बदलने से पहले बातचीत शुरू करें।';

  @override
  String userProfileScreenCouldNotOpenChat(String error) {
    return 'चैट नहीं खोली जा सकी: $error';
  }

  @override
  String userProfileScreenFailedToStartCall(String error) {
    return 'कॉल शुरू नहीं हो सकी: $error';
  }

  @override
  String get userProfileScreenMessage => 'मैसेज';

  @override
  String get userProfileScreenAudioCall => 'ऑडियो कॉल';

  @override
  String get userProfileScreenVideoCall => 'वीडियो कॉल';

  @override
  String get userProfileScreenAddFriend => 'फ्रेंड बनाएं';

  @override
  String get userProfileScreenRequested => 'भेजी गई';

  @override
  String get userProfileScreenAcceptRequest => 'स्वीकारें';

  @override
  String get userProfileScreenRequestSent => 'फ्रेंड रिक्वेस्ट भेजी गई';

  @override
  String get userProfileScreenRequestAccepted =>
      'फ्रेंड रिक्वेस्ट स्वीकार की गई';

  @override
  String userProfileScreenRequestFailed(String error) {
    return 'रिक्वेस्ट नहीं भेजी जा सकी: $error';
  }

  @override
  String get userProfileScreenTalkmosUsername => 'Talkmos यूज़रनेम';

  @override
  String get userProfileScreenUsernameCopied => 'यूज़रनेम कॉपी किया गया';

  @override
  String get userProfileScreenPhone => 'फ़ोन';

  @override
  String get userProfileScreenPhoneNumberCopied => 'फ़ोन नंबर कॉपी किया गया';

  @override
  String get userProfileScreenSharedMedia => 'शेयर की गई मीडिया';

  @override
  String get userProfileScreenMuted => 'म्यूट किया गया';

  @override
  String get userProfileScreenOn => 'चालू';

  @override
  String get userProfileScreenMediaVisibility => 'मीडिया दृश्यता';

  @override
  String get userProfileScreenUnblockContact => 'संपर्क अनब्लॉक करें';

  @override
  String get userProfileScreenBlockContact => 'संपर्क ब्लॉक करें';

  @override
  String get userProfileScreenDefaultBio =>
      'नमस्ते! मैं Talkmos इस्तेमाल कर रहा/रही हूं';

  @override
  String userProfileScreenUnblockConfirmTitle(String name) {
    return '$name को अनब्लॉक करें?';
  }

  @override
  String userProfileScreenBlockConfirmTitle(String name) {
    return '$name को ब्लॉक करें?';
  }

  @override
  String get userProfileScreenUnblockConfirmBody =>
      'अब आप एक-दूसरे को फिर से मैसेज और कॉल कर सकेंगे।';

  @override
  String get userProfileScreenBlockConfirmBody =>
      'अब वे आपको मैसेज या कॉल नहीं कर पाएंगे, और आप भी उन्हें मैसेज या कॉल नहीं कर पाएंगे।';

  @override
  String userProfileScreenUnblockedToast(String name) {
    return '$name को अनब्लॉक कर दिया गया';
  }

  @override
  String userProfileScreenBlockedToast(String name) {
    return '$name को ब्लॉक कर दिया गया';
  }

  @override
  String userProfileScreenFailedToUpdateBlockStatus(String error) {
    return 'ब्लॉक स्थिति अपडेट नहीं हो सकी: $error';
  }

  @override
  String get userProfileScreenShareContact => 'संपर्क शेयर करें';

  @override
  String get userProfileScreenContactCopiedToClipboard =>
      'संपर्क क्लिपबोर्ड में कॉपी किया गया';

  @override
  String get activeCallScreenAddToCall => 'कॉल में जोड़ें';

  @override
  String get activeCallScreenShareScreen => 'स्क्रीन शेयर करें';

  @override
  String get activeCallScreenStopSharingScreen => 'शेयर करना बंद करें';

  @override
  String get activeCallScreenNoFriendsAvailable =>
      'आमंत्रित करने के लिए कोई दोस्त उपलब्ध नहीं है';

  @override
  String get activeCallScreenNoContactsAvailable =>
      'आमंत्रित करने के लिए कोई उपलब्ध नहीं है';

  @override
  String activeCallScreenCallingName(String name) {
    return '$name को कॉल किया जा रहा है…';
  }

  @override
  String activeCallScreenConnectingVideoWith(String name) {
    return '$name के साथ वीडियो कनेक्ट हो रहा है...';
  }

  @override
  String get activeCallScreenReconnecting => 'फिर से कनेक्ट हो रहा है…';

  @override
  String get activeCallScreenCameraOff => 'कैमरा बंद है';

  @override
  String get activeCallScreenCalling => 'कॉल हो रही है...';

  @override
  String get activeCallScreenRinging => 'रिंग हो रही है...';

  @override
  String get activeCallScreenEncryptedCall => 'एन्क्रिप्टेड कॉल';

  @override
  String get activeCallScreenStartVideo => 'वीडियो शुरू करें';

  @override
  String get activeCallScreenStopVideo => 'वीडियो रोकें';

  @override
  String get activeCallScreenMore => 'अधिक';

  @override
  String get activeCallScreenEndCall => 'कॉल समाप्त करें';

  @override
  String get activeCallBannerTapToReturn => 'कॉल पर वापस जाने के लिए टैप करें';

  @override
  String get activeCallBannerOngoingCall => 'चालू कॉल';

  @override
  String get friendRequestsScreenTitle => 'फ़्रेंड रिक्वेस्ट';

  @override
  String get friendRequestsScreenReceivedTab => 'प्राप्त';

  @override
  String get friendRequestsScreenSentTab => 'भेजी गई';

  @override
  String get friendRequestsScreenSectionSent => 'आपके द्वारा भेजी गई रिक्वेस्ट';

  @override
  String get friendRequestsScreenSectionReceived => 'आपको मिली रिक्वेस्ट';

  @override
  String get friendRequestsScreenNoReceived =>
      'कोई लंबित प्राप्त रिक्वेस्ट नहीं है।';

  @override
  String get friendRequestsScreenNoSent =>
      'कोई लंबित भेजी गई रिक्वेस्ट नहीं है।';

  @override
  String get friendRequestsScreenDefaultUserName => 'उपयोगकर्ता';

  @override
  String get friendRequestsScreenPrivacyHint =>
      'केवल उन्हीं लोगों की रिक्वेस्ट स्वीकार करें जिन्हें आप जानते और भरोसा करते हैं।';

  @override
  String get friendRequestsScreenLearnMorePrivacy =>
      'गोपनीयता के बारे में और जानें >';

  @override
  String friendRequestsScreenAcceptError(String error) {
    return 'रिक्वेस्ट स्वीकार नहीं हो सकी: $error';
  }

  @override
  String get friendRequestsScreenPending => 'लंबित';

  @override
  String get userSearchScreenPrivateAccount =>
      'This account is private. Send a friend request to see their profile.';

  @override
  String get userSearchScreenTitle => 'संपर्क खोजें';

  @override
  String get userSearchScreenSearchHint => 'नाम, ईमेल या फ़ोन नंबर से खोजें...';

  @override
  String get userSearchScreenBannerTitle => 'Talkmos ID से उपयोगकर्ता खोजें';

  @override
  String get userSearchScreenBannerSubtitle =>
      'आप लोगों को उनकी Talkmos ID से खोज सकते हैं';

  @override
  String get userSearchScreenEmptyPrompt => 'चैट करने के लिए लोगों को खोजें';

  @override
  String get userSearchScreenNoResults => 'कोई उपयोगकर्ता नहीं मिला';

  @override
  String get userSearchScreenResultsHeader => 'खोज परिणाम';

  @override
  String get userSearchScreenDefaultUserName => 'उपयोगकर्ता';

  @override
  String get userSearchScreenFriendStatus => 'फ्रेंड';

  @override
  String get userSearchScreenPendingStatus => 'लंबित';

  @override
  String get userSearchScreenRequestAccepted =>
      'फ़्रेंड रिक्वेस्ट स्वीकार कर ली गई!';

  @override
  String get userSearchScreenRequestSent => 'फ़्रेंड रिक्वेस्ट भेज दी गई!';

  @override
  String userSearchScreenSendRequestError(String error) {
    return 'रिक्वेस्ट भेजी नहीं जा सकी: $error';
  }

  @override
  String get callsScreenAm => 'AM';

  @override
  String get callsScreenPm => 'PM';

  @override
  String get callsScreenWeekdayMon => 'सोम';

  @override
  String get callsScreenWeekdayTue => 'मंगल';

  @override
  String get callsScreenWeekdayWed => 'बुध';

  @override
  String get callsScreenWeekdayThu => 'गुरु';

  @override
  String get callsScreenWeekdayFri => 'शुक्र';

  @override
  String get callsScreenWeekdaySat => 'शनि';

  @override
  String get callsScreenWeekdaySun => 'रवि';

  @override
  String get callsScreenNoHistory => 'कोई कॉल इतिहास नहीं मिला।';

  @override
  String get callsScreenNoMissedCalls => 'कोई मिस्ड कॉल नहीं है।';

  @override
  String get callsScreenNoIncomingCalls => 'कोई इनकमिंग कॉल नहीं है।';

  @override
  String get callsScreenNoOutgoingCalls => 'कोई आउटगोइंग कॉल नहीं है।';

  @override
  String get callsScreenNoSearchResults => 'कोई कॉल नहीं मिली';

  @override
  String get callsScreenOlder => 'पुराने';

  @override
  String get callsScreenFilterAll => 'सभी';

  @override
  String get callsScreenFilterMissed => 'मिस्ड';

  @override
  String get callsScreenFilterIncoming => 'इनकमिंग';

  @override
  String get callsScreenFilterOutgoing => 'आउटगोइंग';

  @override
  String get callsScreenDefaultUserName => 'उपयोगकर्ता';

  @override
  String get callsScreenCannotPlaceCallMissingDetails =>
      'कॉल नहीं हो सकी: उपयोगकर्ता की जानकारी अनुपलब्ध';

  @override
  String get callsScreenCannotPlaceCallGroupNotFound =>
      'कॉल नहीं हो सकी: समूह वार्तालाप नहीं मिला';

  @override
  String get callsScreenCannotPlaceCallChatNotFound =>
      'कॉल नहीं हो सकी: चैट नहीं मिली';

  @override
  String callsScreenFailedToStartCall(String error) {
    return 'कॉल शुरू नहीं हो सकी: $error';
  }

  @override
  String get soundSelectorRowIncludedWithTalkmos => 'Talkmos के साथ शामिल';

  @override
  String get soundSelectorRowPhoneDefault => 'फ़ोन डिफ़ॉल्ट';

  @override
  String get soundSelectorRowFollowPhoneTone =>
      'इस फ़ोन के अपने टोन का उपयोग करें';

  @override
  String get soundSelectorRowChooseFromDevice => 'डिवाइस से चुनें';

  @override
  String get soundSelectorRowPickAnyTone => 'इस फ़ोन का कोई भी टोन चुनें';

  @override
  String get soundSelectorRowSilentSubtitle => 'बिना ध्वनि के सूचना दिखाएं';

  @override
  String get communityScreenJoinedSuccess =>
      'समुदाय में सफलतापूर्वक शामिल हो गए!';

  @override
  String communityScreenJoinError(String error) {
    return 'शामिल होने में त्रुटि: $error';
  }

  @override
  String get communityScreenDefaultName => 'समुदाय';

  @override
  String get communityScreenSearchComingSoon => 'समुदाय खोज जल्द आ रही है!';

  @override
  String get communityScreenNotificationsComingSoon =>
      'सूचनाएं जल्द आ रही हैं।';

  @override
  String get communityScreenYourCommunities => 'आपके समुदाय';

  @override
  String get communityScreenDiscoverSection => 'खोजें';

  @override
  String get communityScreenLoadError => 'समुदाय लोड नहीं हो सके';

  @override
  String get communityScreenNewCommunity => 'नया समुदाय';

  @override
  String get communityScreenUntitled => 'शीर्षक रहित';

  @override
  String get communityScreenAnnouncements => 'घोषणाएं';

  @override
  String communityScreenMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सदस्य',
      one: '$count सदस्य',
    );
    return '$_temp0';
  }

  @override
  String get communityScreenNoDescription => 'कोई विवरण नहीं';

  @override
  String get communityScreenPreviewPhoto => '📷 फ़ोटो';

  @override
  String get communityScreenPreviewVideo => '🎥 वीडियो';

  @override
  String get communityScreenPreviewAudio => '🎵 ऑडियो';

  @override
  String get communityScreenPreviewFile => '📄 फ़ाइल';

  @override
  String get communityScreenJoinedLabel => 'शामिल हो गए';

  @override
  String get communityScreenJoinButton => 'शामिल हों';

  @override
  String get communityScreenIntroTitle => 'समुदायों से परिचय';

  @override
  String get communityScreenIntroBody =>
      'समुदाय सदस्यों को विषय-आधारित समूहों में एक साथ लाते हैं, और प्रासंगिक घोषणाएं पाना आसान बनाते हैं।';

  @override
  String get communityScreenStartButton => 'अपना समुदाय शुरू करें';

  @override
  String communityScreenImageUploadError(String error) {
    return 'छवि अपलोड करने में विफल: $error';
  }

  @override
  String get communityScreenCreateSuccess => 'समुदाय सफलतापूर्वक बन गया!';

  @override
  String get communityScreenNameLabel => 'समुदाय का नाम';

  @override
  String get communityScreenDescriptionLabel => 'विवरण';

  @override
  String get communityScreenCategoryLabel => 'श्रेणी';

  @override
  String get communityScreenCreateButton => 'समुदाय बनाएं';

  @override
  String communityDetailScreenLeaveError(String error) {
    return 'छोड़ने में विफल: $error';
  }

  @override
  String get communityDetailScreenLeaveTitle => 'समुदाय छोड़ें?';

  @override
  String communityDetailScreenLeaveBody(String name) {
    return 'आपको $name से संदेश मिलना बंद हो जाएगा।';
  }

  @override
  String get communityDetailScreenTitle => 'समुदाय जानकारी';

  @override
  String get communityDetailScreenShareInvite => 'आमंत्रण लिंक साझा करें';

  @override
  String get communityDetailScreenLeaveButton => 'समुदाय छोड़ें';

  @override
  String communityDetailScreenMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सदस्य',
      one: '$count सदस्य',
    );
    return '$_temp0';
  }

  @override
  String get communityDetailScreenMembersHeader => 'सदस्य';

  @override
  String communityDetailScreenMembersHeaderCount(int count) {
    return 'सदस्य ($count)';
  }

  @override
  String communityDetailScreenMembersLoadError(String error) {
    return 'सदस्य लोड नहीं हो सके: $error';
  }

  @override
  String get createStoryScreenCameraPhoto => 'कैमरा फ़ोटो';

  @override
  String get createStoryScreenCameraVideo => 'कैमरा वीडियो';

  @override
  String get createStoryScreenTitle => 'नई स्थिति';

  @override
  String createStoryScreenTitleWithCount(int count) {
    return 'नई स्थिति ($count)';
  }

  @override
  String get createStoryScreenAddMoreTooltip => 'और जोड़ें';

  @override
  String get createStoryScreenShare => 'शेयर करें';

  @override
  String get createStoryScreenPickerTitle => 'फ़ोटो या वीडियो स्थिति शेयर करें';

  @override
  String get createStoryScreenPickerSubtitle =>
      'एक साथ पोस्ट करने के लिए एक से अधिक चुनें';

  @override
  String get createStoryScreenPhotoOption => 'फ़ोटो';

  @override
  String get createStoryScreenCaptionHint => 'कैप्शन जोड़ें…';

  @override
  String get createStoryScreenAddStickerTooltip => 'स्टिकर जोड़ें';

  @override
  String get createStoryScreenFilterTooltip => 'फ़िल्टर';

  @override
  String get storyViewerScreenVideoLoadError => 'वीडियो लोड करने में विफल';

  @override
  String get storyViewerScreenDeleteStory => 'स्टेटस हटाएं';

  @override
  String get storyViewerScreenDeleteConfirm =>
      'यह स्टेटस हटाएं? जिन्होंने इसे नहीं देखा, वे अब नहीं देख पाएंगे।';

  @override
  String get storyViewerScreenDeleted => 'स्टेटस हटा दिया गया';

  @override
  String get storyViewerScreenDeleteFailed => 'यह स्टेटस हटाया नहीं जा सका';

  @override
  String get mainNavigationNewGroup => 'नया समूह';

  @override
  String get mainNavigationFindContacts => 'संपर्क खोजें';

  @override
  String get mainNavigationFriendRequests => 'मित्र अनुरोध';

  @override
  String get mainNavigationSavedMessages => 'सहेजे गए संदेश';

  @override
  String get mainNavigationLightMode => 'लाइट मोड';

  @override
  String get mainNavigationDarkMode => 'डार्क मोड';

  @override
  String get mainNavigationInviteFriends => 'मित्रों को आमंत्रित करें';

  @override
  String get mainNavigationLogout => 'लॉग आउट';

  @override
  String get mainNavigationGuest => 'अतिथि';

  @override
  String get mainNavigationChatsTab => 'चैट्स';

  @override
  String get privacySettingsScreenVisibilityContacts => 'संपर्क';

  @override
  String get privacySettingsScreenVisibilityNobody => 'कोई नहीं';
}
