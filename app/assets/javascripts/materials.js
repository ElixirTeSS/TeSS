function makeZenodoVideo(video_element, files_url, preferred_key) {
    const videoExtensions = ['.mp4', '.webm', '.ogg', '.ogv', '.mov', '.m4v', '.mkv'];
    const audioExtensions = ['.mp3', '.ogg', '.wav', '.aac', '.flac', '.opus'];
    video_element.parentElement.style.display = 'none';

    fetch(files_url)
        .then(response => response.json())
        .then(data => {
            let video_file = null;
            if (preferred_key != null) {
                video_file = data.entries.find(file => file.key === String(preferred_key));
            }
            if (!video_file) {
                video_file = data.entries.find(file => videoExtensions.some(ext => file.key.toLowerCase().endsWith(ext)));
            }
            if (!video_file) { // fallback to audio
                video_file = data.entries.find(file => audioExtensions.some(ext => file.key.toLowerCase().endsWith(ext)));
            }
            if (video_file) {
                const video_url = video_file.links.content;
                video_element.src = video_url;
                video_element.style.display = 'block';
                video_element.parentElement.style.display = 'flex';
            }
        })
        .catch(error => console.error('Error fetching Zenodo files:', error));
}

$(document).on('ready turbolinks:load', function() {
    $('#zenodo-video').each(function() {
        const files_url = this.dataset.zenodoFilesUrl;
        const preferred_key = this.dataset.zenodoPreferredKey;
        makeZenodoVideo(this, files_url, preferred_key);
    });
});
