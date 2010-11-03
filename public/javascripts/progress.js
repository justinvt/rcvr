var completed = 0;
var update_interval = 1500;//milliseconds
var progress_update_base_url = "/progress/"
var progress_selector = ".progress"
var status_selector   = ".status"
var video_selector=".links .video"
var audio_selector=".links .audio"
var title;
var status_messages = {
	downloading: "Downloading source video",
	converting:  "Converting audio (this should take less than a minute) ",
	completed:   "Completed"
}

function filenameToLink(remote_filename){
	var file_parts = remote_filename.split("/public/")
	var path_paths = remote_filename.split("/")
	var basename   = path_paths[path_paths.length - 1]
	var filename = "/" + file_parts[file_parts.length - 1]
	var download_mp3 = "<a href =\"" + filename + "\">" + basename + "</a>"
	return download_mp3
}

function jsonToVideoLink(json){
	var video_link = "<a href =\"" + json.url + "\">" + [title,json.ext].join(".") + "</a>"
	return video_link
}

function setStatus(state){
	$(status_selector).html("<span class='" + state + "'>" + status_messages[state] + "</span>")
}

function getProgress(video_id){
	$.ajax({
		url: progress_update_base_url + video_id,
		data: {},
		success: function(json){
			completed      = json.progress
			audio_progress = json.audio_progress
			audio_filename = json.audio_filename
			if(completed>99){
				if(audio_filename==""){
					setStatus("converting");
					$(progress_selector).html("")
					$(video_selector).html("<span class='label'>video:</span> " + jsonToVideoLink(json));
					setTimeout("getProgress(\"" + video_id + "\")", update_interval )
				}
				else{
					setStatus("completed");
					$(progress_selector).html("")
					$(audio_selector).html("<span class='label'>audio:</span> " + filenameToLink(audio_filename));
					$(video_selector).html("<span class='label'>video:</span> " + jsonToVideoLink(json));
				}
			}
			else{
				setStatus("downloading");
				$(progress_selector).html("<span class='percent'>" + completed + "</span><span class='percent_sign'>%</span>")
				setTimeout("getProgress(\"" + video_id + "\")", update_interval )
			}
		},
		dataType: "json"
	});
}


$(document).ready(function(){
	if(location.href.match(/downloading/)){
		title = $(".title").text()
		var url_parts =  location.href.split("/")
		var video_id = url_parts[url_parts.length - 1]
		getProgress(video_id)
	}
})