function getProgress(video_id){
	$.ajax({
		url: "/progress/" + video_id,
		data: {},
		success: function(json){
			var completed = 100 * (parseFloat(json.progress) / parseFloat(json.size))
			$(".progress").text(completed + "%")
		},
		dataType: "json"
	});

	setTimeout("getProgress(\"" + video_id + "\")", 4000)
}


$(document).ready(function(){
	if(location.href.match(/downloading/)){
		var url_parts =  location.href.split("/")
		var video_id = url_parts[url_parts.length - 1]
		getProgress(video_id)
	}
	
})