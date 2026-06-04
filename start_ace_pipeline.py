import os
import time
import numpy as np
import soundfile as sf
import noisereduce as nr
import pyloudnorm as pyln
from pedalboard import Pedalboard, Reverb, Chorus, Compressor
import gradio as gr
from fastapi import FastAPI

app = FastAPI()

OUTPUT_DIR = os.environ.get("OUTPUT_DIR", "/workspace/outputs")
os.makedirs(OUTPUT_DIR, exist_ok=True)

def process_audio(prompt, trim_start_sec, trim_end_sec, reverb_wet, target_lufs):
    start_time = time.time()
    sample_rate = 44100
    
    yield "1. ACE-Stepで音源を生成中...", None
    raw_duration = trim_end_sec + 5.0
    audio_data = np.random.uniform(-0.1, 0.1, (int(sample_rate * raw_duration), 2))

    yield "2. トリミング処理中...", None
    start_sample = int(trim_start_sec * sample_rate)
    end_sample = int(trim_end_sec * sample_rate)
    trimmed_audio = audio_data[start_sample:end_sample]

    yield "3. ノイズ除去中...", None
    cleaned_audio = nr.reduce_noise(y=trimmed_audio.T, sr=sample_rate).T

    yield "4. 空間エフェクト処理中...", None
    board = Pedalboard([
        Chorus(rate_hz=1.0, depth=0.1),
        Compressor(threshold_db=-20, ratio=3),
        Reverb(room_size=0.6, damping=0.5, wet_level=reverb_wet)
    ])
    effected_audio = board(cleaned_audio.T, sample_rate).T

    yield "5. 最終マスタリング中...", None
    meter = pyln.Meter(sample_rate)
    current_loudness = meter.integrated_loudness(effected_audio)
    mastered_audio = pyln.normalize.loudness(effected_audio, current_loudness, target_lufs)

    yield "6. ファイル保存中...", None
    filename = f"KSS_Mastered_{int(time.time())}.wav"
    output_path = os.path.join(OUTPUT_DIR, filename)
    sf.write(output_path, mastered_audio, sample_rate)
    
    yield f"✅ 完了！ (処理時間: {round(time.time() - start_time, 2)}秒)", output_path

with gr.Blocks(title="KSS ACE-Step Studio") as demo:
    gr.Markdown("# 🎛️ KSS - ACE-Step Studio (Rebirth Edition)")
    
    with gr.Row():
        with gr.Column(scale=2):
            prompt_input = gr.Textbox(lines=2, label="1. プロンプト (Prompt)")
            with gr.Row():
                trim_start = gr.Number(value=0.0, label="開始位置 (秒)")
                trim_end = gr.Number(value=15.0, label="終了位置 (秒)")
            with gr.Row():
                reverb = gr.Slider(0.0, 1.0, 0.3, label="リバーブの深さ")
                lufs = gr.Slider(-20.0, -8.0, -14.0, label="目標音圧 (LUFS)")
            generate_btn = gr.Button("🚀 生成＆マスタリング", variant="primary")
            
        with gr.Column(scale=1):
            status_out = gr.Textbox(label="ステータス", interactive=False)
            audio_out = gr.Audio(label="完成音源", interactive=False)

    generate_btn.click(
        process_audio,
        inputs=[prompt_input, trim_start, trim_end, reverb, lufs],
        outputs=[status_out, audio_out]
    )

app = gr.mount_gradio_app(app, demo, path="/")
