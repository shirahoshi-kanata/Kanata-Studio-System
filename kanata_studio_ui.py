
import gradio as gr
import urllib.request
import json
import random

COMFYUI_URL = 'http://127.0.0.1:6006/prompt'

def send_to_comfyui(workflow_json):
    data = json.dumps({'prompt': workflow_json}).encode('utf-8')
    req = urllib.request.Request(COMFYUI_URL, data=data, headers={'Content-Type': 'application/json'})
    try:
        with urllib.request.urlopen(req) as response:
            return json.loads(response.read())
    except Exception as e:
        return {'error': str(e)}

def generate_music(lyrics, prompt, neg_prompt, init_audio, duration, seed, cfg, steps, audiosr_str, audiosr_bypass, demucs_on):
    if seed == -1: seed = random.randint(1, 1000000000)
    workflow = {
        '10': {'class_type': 'ACETalker', 'inputs': {'lyrics': lyrics if lyrics else '', 'style_prompt': prompt, 'negative_prompt': neg_prompt, 'duration': duration, 'seed': seed, 'cfg_scale': cfg, 'steps': steps}},
        '20': {'class_type': 'AudioSRNode', 'inputs': {'audio': ['10', 0], 'strength': audiosr_str / 100.0, 'bypass': audiosr_bypass}},
        '30': {'class_type': 'DemucsNode', 'inputs': {'audio': ['20', 0], 'enabled': demucs_on}},
        '40': {'class_type': 'SaveAudio', 'inputs': {'audio': ['30', 0], 'filename_prefix': 'KanataStudio_Track'}}
    }
    result = send_to_comfyui(workflow)
    if 'error' in result:
        return None, None, None
    return None, None, None

theme = gr.themes.Monochrome(primary_hue='indigo')
with gr.Blocks(theme=theme, title='Kanata Studio') as demo:
    gr.Markdown('# 🎛 Kanata Studio - ACE-Step 1.5 XL')
    with gr.Row():
        with gr.Column(scale=2):
            lyrics = gr.Textbox(label='🎤 歌詞', lines=6)
            prompt = gr.Textbox(label='🎵 ジャンル', placeholder='例: J-Pop')
            neg_prompt = gr.Textbox(label='🚫 ネガティブ', value='lo-fi, bad quality')
            init_audio = gr.Audio(label='ベース音源', type='filepath')
        with gr.Column(scale=1):
            duration = gr.Slider(minimum=10, maximum=120, step=1, value=30, label='⏱ 秒数')
            seed = gr.Number(label='🔢 シード (-1でランダム)', value=-1, precision=0)
            cfg = gr.Slider(minimum=1.0, maximum=10.0, step=0.1, value=3.5, label='🎚 CFG')
            steps = gr.Slider(minimum=10, maximum=100, step=1, value=20, label='👟 ステップ数')
            audiosr_str = gr.Slider(minimum=0, maximum=100, step=1, value=80, label='AudioSR 強度')
            audiosr_bypass = gr.Checkbox(label='AudioSR バイパス', value=False)
            demucs_on = gr.Checkbox(label='Demucs 音源分離', value=True)
    generate_btn = gr.Button('🚀 音楽を生成', variant='primary', size='lg')
    output_main = gr.Audio(label='🎵 完成版トラック', interactive=False)
    output_vocal = gr.Audio(label='🎤 ボーカルのみ', interactive=False)
    output_inst = gr.Audio(label='🎸 伴奏のみ', interactive=False)
    generate_btn.click(fn=generate_music, inputs=[lyrics, prompt, neg_prompt, init_audio, duration, seed, cfg, steps, audiosr_str, audiosr_bypass, demucs_on], outputs=[output_main, output_vocal, output_inst])

if __name__ == '__main__':
    demo.launch(server_name='0.0.0.0', server_port=7860, share=False)
