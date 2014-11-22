/*
self.addEventListener('message', function(e) {
	importScripts('/assets/jquery.js');
	var lines = e.data.text.split("\n");
	for (var i = 0; i < lines.length; i += e.data.threads) {
		var to_send = {
			data : new Array()
		}
		self.postMessage(i);
		for (var j = 0; j < e.data.threads; j ++) {
			if ((i + j) < lines.length) {
				to_send.data[j] = lines[i + j];
  			self.postMessage(lines[i + j]);
  		}
  	}
  	if(to_send.data.length > 0) {
  		to_send.http_method = e.data.http_method;
  		to_send.path = e.data.path;
  		to_send.headers = e.data.headers;
  		to_send.body = e.data.body;
  		self.postMessage(JSON.stringify(to_send));
  		var xhr=new XMLHttpRequest();

  		$.ajax({
  			type : "POST",
  			url : "/cloud/execute_bulk_requests/" + data.cloud,
  			data : JSON.stringify(to_send),
  			dataType : "json"
			});
  	}
  }
}, false);
*/