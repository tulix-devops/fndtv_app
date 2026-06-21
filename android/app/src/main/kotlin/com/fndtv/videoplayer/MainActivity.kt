package com.fndtv.videoplayer

import com.ryanheise.audioservice.AudioServiceActivity

// Must extend AudioServiceActivity (not FlutterActivity) so just_audio_background
// can attach the media session to the correct FlutterEngine.
class MainActivity : AudioServiceActivity()
