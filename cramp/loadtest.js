var sys = require('sys');
var counter = 0;
var WebSocket = require('websocket-client').WebSocket;
var intervalId = 0;

var createConnection = function() {
  var count = counter;
  counter++;
  var ws = new WebSocket('ws://localhost:8080/live');
  ws.addListener('data', function(buf) {
      sys.debug('Got data (' + count + '): ' + sys.inspect(buf));
  });
  ws.onmessage = function(m) {
      sys.debug('Got message: (' + count + '): ' + m);
  }
  if (counter > 200) {
    clearInterval(intervalId);
  }
}

//for (i = 0; i < 249; i++) {
//  createConnection();
//}


intervalId = setInterval(createConnection, 100);
