var completed = 0;
function getProgress(video_id){
	$.ajax({
		url: "/progress/" + video_id,
		data: {},
		success: function(json){
			completed      = json.progress
			audio_progress = json.audio_progress
			audio_filename = json.audio_filename
			if(json.audio_filename != ""){
				var file_parts = json.audio_filename.split("/public/")
				var path_paths = json.audio_filename.split("/")
				var basename   = path_paths[path_paths.length - 1]
				var filename = "/" + file_parts[file_parts.length - 1]
				var download_mp3 = "<a href =\"" + filename + "\">" + basename + "</a>"
				$(".progress").html(download_mp3)
			}
			else if(completed.toString() != "100"){
				$(".progress").html("Downloading source video <br/>" + completed + "%")
				setTimeout("getProgress(\"" + video_id + "\")", 1500)
			}
			else{
				$(".progress").html("Converting audio (this should take less than a minute) ")
				setTimeout("getProgress(\"" + video_id + "\")", 1500)
			}

			
		},
		dataType: "json"
	});


	
}


$(document).ready(function(){
	if(location.href.match(/downloading/)){
		var url_parts =  location.href.split("/")
		var video_id = url_parts[url_parts.length - 1]
		getProgress(video_id)
	}
	
})