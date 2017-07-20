window.addEventListener('load', function () {
  // 始めに、通知の許可を得ているかを確認しましょう
  // 得ていなければ、尋ねましょう
  if (window.Notification && Notification.permission !== "granted") {
    Notification.requestPermission(function (status) {
      if (Notification.permission !== status) {
        Notification.permission = status;
      }
    });
  }
});

// Notification表示
function spawnNotification(theBody, theIcon, theTitle) {
  var options = {
    body: theBody,
    icon: theIcon,
    requireInteraction: true
//    tag: 'scm-notigication'
  }
  var n = new Notification(theTitle, options);
  setTimeout(n.close.bind(n), 30 * 60 * 1000);  // 30minuts
}

