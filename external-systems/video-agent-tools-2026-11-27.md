# Video agent tools — Instagram DgNd6ydkU1I

Source: https://www.instagram.com/p/DgNd6ydkU1I/ ; screenshots supplied for tools 1–8 and 10. Tool 9 (slide 10) missing. All nine upstream READMEs retrieved successfully. Installation recipes are on-demand, not runtime qualified. Review scripts, pin versions, use isolated environments and licensed media.

## HyperFrames

Category: external-systems / video and media.

Upstream: https://github.com/heygen-com/hyperframes

Download: `git clone https://github.com/heygen-com/hyperframes.git`

Setup: npx skills add heygen-com/hyperframes; npx hyperframes init my-video; npx hyperframes render.

Requirements / policy: Node 22+, FFmpeg; Apache-2.0.

## FFmpeg Skill

Category: external-skills / video and media.

Upstream: https://github.com/kajisho5/ffmpeg-skill

Download: `git clone https://github.com/kajisho5/ffmpeg-skill.git`

Setup: npx ffmpeg-skill --codex (or npx ffmpeg-skill for Claude); npx ffmpeg-skill doctor.

Requirements / policy: Node 16+, Python 3.10+, FFmpeg; MIT.

## Whisper

Category: external-systems / video and media.

Upstream: https://github.com/openai/whisper

Download: `git clone https://github.com/openai/whisper.git`

Setup: python -m pip install openai-whisper; whisper --help.

Requirements / policy: Python/PyTorch, FFmpeg, model weights; MIT.

## yt-dlp

Category: external-systems / video and media.

Upstream: https://github.com/yt-dlp/yt-dlp

Download: `git clone https://github.com/yt-dlp/yt-dlp.git`

Setup: python -m pip install 'yt-dlp[default]'; yt-dlp --version.

Requirements / policy: FFmpeg recommended; authorized downloads only.

## Claude Shorts

Category: external-skills / video and media.

Upstream: https://github.com/AgriciDaniel/claude-shorts

Download: `git clone https://github.com/AgriciDaniel/claude-shorts.git`

Setup: cd claude-shorts; bash setup.sh; bash install.sh.

Requirements / policy: Python, Node, FFmpeg, Unix/WSL; MIT.

## Ghost Editor

Category: external-skills / video and media.

Upstream: https://github.com/kurbaitaev/ghost-editor

Download: `git clone https://github.com/kurbaitaev/ghost-editor.git`

Setup: clone into ~/.claude/skills/ghost-editor; follow docs/INSTALL.md.

Requirements / policy: FFmpeg, Node, Python, Whisper, OpenCV; MIT.

## Motion Skills

Category: external-skills / video and media.

Upstream: https://github.com/iart-ai/motion-skills

Download: `git clone https://github.com/iart-ai/motion-skills.git`

Setup: npx skills add iart-ai/tiktok-video-skills or npx skills add iart-ai/data-animation-skills.

Requirements / policy: Select individual pack; review its license.

## Awesome Claude Video Skills

Category: external-skills / video and media.

Upstream: https://github.com/zhuyansen/awesome-claude-video-skills

Download: `git clone https://github.com/zhuyansen/awesome-claude-video-skills.git`

Setup: Browse README and install selected upstream tool only.

Requirements / policy: Reference catalog; third-party security grades not independent verification.

## MotionClone

Category: external-systems / video and media.

Upstream: https://github.com/LPengYang/MotionClone

Download: `git clone https://github.com/LPengYang/MotionClone.git`

Setup: cd MotionClone; conda env create -f environment.yaml; conda activate motionclone.

Requirements / policy: Python 3.11.3 recommended; GPU/model weights and license review.

