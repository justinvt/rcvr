var completed = 0;
var update_interval = 1500;//milliseconds
var progress_update_base_url = "/progress/"
var reprocess_base_url = "/youtube/reprocess/"
var redownload_base_url = "/youtube/redownload/"
var retag_base_url = "/youtube/retag/"
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

function reprocessAudio(video_id){
	var reprocess_url = reprocess_base_url + video_id
	$.get(reprocess_url, function(data){
		return true
	})
}

function redownload(video_id){
	var redownload_url = redownload_base_url + video_id
	$.get(redownload_url, function(data){
		return true
	})
}

function retag(video_id){
	var retag_url = retag_base_url + video_id
	$.get(retag_url, function(data){
		return true
	})
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
				// File is done downloading, not yet converted
				if(audio_filename==""){
					setStatus("converting");
					$(progress_selector).addClass("conversion").html("<span class='percent'>" + audio_progress + "</span><span class='percent_sign'>%</span>")
					$(video_selector).html("<span class='label'>video:</span> " + jsonToVideoLink(json));
					setTimeout("getProgress(\"" + video_id + "\")", update_interval )
				}
				// File has been downloaded and conversion is complete
				else{
					setStatus("completed");
					$(progress_selector).html("")
					$(audio_selector).html("<span class='label'>audio:</span> " + filenameToLink(audio_filename));
					$(video_selector).html("<span class='label'>video:</span> " + jsonToVideoLink(json));
				}
			}
			// File is in the process of downloading
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
		title = $("h1 .title").text()
		var url_parts =  location.href.split("/")
		var video_id = url_parts[url_parts.length - 1]
		getProgress(video_id)
		$("h1").after("<div class='controls'><input id='retag' type='button' value='retag audio'/><input id='redownload' type='button' value='restart download'/><input id='reprocess' type='button' value='reprocess audio'/></div>")
		$("#reprocess").click(function(){
			reprocessAudio(video_id)
			setTimeout("getProgress(\"" + video_id + "\")", update_interval )
		})
		$("#redownload").click(function(){
			redownload(video_id)
			setTimeout("getProgress(\"" + video_id + "\")", update_interval )
		})
		$("#retag").click(function(){
			retag(video_id)
			setTimeout("getProgress(\"" + video_id + "\")", update_interval )
		})
	}
})