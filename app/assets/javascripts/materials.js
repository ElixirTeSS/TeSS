function make_zenodo_video(video_element, files_url, preferred_key) {
    const videoExtensions = ['.mp4', '.webm', '.ogg', '.ogv', '.mov', '.m4v', '.mkv'];
    const audioExtensions = ['.mp3', '.ogg', '.wav', '.aac', '.flac', '.opus'];

    fetch(files_url)
        .then(response => response.json())
        .then(data => {
            let video_file = data.entries.find(file => file.key == preferred_key);
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
            }
        })
        .catch(error => console.error('Error fetching Zenodo files:', error));
}